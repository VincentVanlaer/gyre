! Module   : gyre_rad_search
! Purpose  : radial adiabatic mode searching
!
! Copyright 2013 Rich Townsend
!
! This file is part of GYRE. GYRE is free software: you can
! redistribute it and/or modify it under the terms of the GNU General
! Public License as published by the Free Software Foundation, version 3.
!
! GYRE is distributed in the hope that it will be useful, but WITHOUT
! ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
! or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public
! License for more details.
!
! You should have received a copy of the GNU General Public License
! along with this program.  If not, see <http://www.gnu.org/licenses/>.

$include 'core.inc'

module gyre_rad_search

  ! Uses

  use core_kinds
  use core_parallel

  use gyre_numpar
  use gyre_rad_bvp
  use gyre_rad_discfunc
  use gyre_mode
  use gyre_ext_arith
  use gyre_util

  use ISO_FORTRAN_ENV

  ! No implicit typing

  implicit none

  ! Access specifiers

  private

  public :: rad_scan_search

  ! Procedures

contains

  subroutine rad_scan_search (bp, omega, md)

    type(rad_bvp_t), target, intent(inout) :: bp
    real(WP), intent(in)                   :: omega(:)
    type(mode_t), allocatable, intent(out) :: md(:)

    real(WP), allocatable   :: omega_a(:)
    real(WP), allocatable   :: omega_b(:)
    integer                 :: n_brack
    integer                 :: i_part(MPI_SIZE+1)
    integer                 :: c_beg
    integer                 :: c_end
    integer                 :: c_rate
    type(rad_discfunc_t)    :: df
    type(numpar_t), pointer :: np
    integer                 :: i
    integer                 :: n_iter
    complex(WP)             :: omega_root
    complex(WP)             :: discrim_root
    integer                 :: n_p
    integer                 :: n_g
    $if($MPI)
    integer                 :: p
    $endif

    ! Scan for discriminant root brackets

    call scan(bp, omega, omega_a, omega_b)

    ! Process each bracket to find roots

    if(check_log_level('INFO')) then
       write(OUTPUT_UNIT, 100) form_header('Adiabatic Mode Finding', '=')
100    format(A)
    endif

    call df%init(bp)

    n_brack = SIZE(omega_a)

    call partition_tasks(n_brack, 1, i_part)

    allocate(md(n_brack))

    np => bp%get_np()

    call SYSTEM_CLOCK(c_beg, c_rate)

    $if($MPI)
    call barrier()
    $endif

    root_loop : do i = i_part(MPI_RANK+1), i_part(MPI_RANK+2)-1

       ! Set the discriminant normalization, based on the mid-bracket
       ! frequency

       call bp%set_norm(CMPLX(0.5_WP*(omega_a(i) + omega_b(i)), KIND=WP))

       ! Find the root

       n_iter = np%n_iter_max

       omega_root = df%root(omega_a(i), omega_b(i), 0._WP, n_iter=n_iter)
       $ASSERT(n_iter <= np%n_iter_max,Too many iterations)

       discrim_root = df%eval(omega_root)

       ! Set up the mode

       md(i) = bp%mode(omega_root)

       ! Report

       call md(i)%classify(n_p, n_g)

       if(check_log_level('INFO', MPI_RANK)) then
          write(OUTPUT_UNIT, 110) 'Mode :', n_p-n_g, n_p, n_g, omega_root, ABS(discrim_root), n_iter
110       format(A,3(2X,I6),3(2X,E23.16),2X,I4)
       endif

    end do root_loop

    $if($MPI)
    call barrier()
    $endif

    call SYSTEM_CLOCK(c_end)

    if(check_log_level('INFO')) then
       write(OUTPUT_UNIT, 120) 'Completed ad find; time elapsed:', REAL(c_end-c_beg, WP)/c_rate, 's'
120    format(/A,1X,F10.3,1X,A)
    endif

    ! Broadcast data

    $if($MPI)

    do p = 0, MPI_SIZE-1
       do i = i_part(p+1), i_part(p+2)-1
          call bcast(md(i), p)
       end do
    enddo

    $endif

    ! Finish

    return

  end subroutine rad_scan_search

!****

  subroutine scan (bp, omega, omega_a, omega_b)

    type(rad_bvp_t), target, intent(inout) :: bp
    real(WP), intent(in)                   :: omega(:)
    real(WP), allocatable, intent(out)     :: omega_a(:)
    real(WP), allocatable, intent(out)     :: omega_b(:)

    integer          :: n_omega
    integer          :: i_part(MPI_SIZE+1)
    integer          :: c_beg
    integer          :: c_end
    integer          :: c_rate
    integer          :: i
    type(ext_real_t) :: discrim(SIZE(omega))
    $if($MPI)
    integer          :: recvcounts(MPI_SIZE)
    integer          :: displs(MPI_SIZE)
    $endif
    integer          :: n_brack
    integer          :: i_brack(SIZE(omega))

    ! Calculate the discriminant on the omega abscissa

    if(check_log_level('INFO')) then
       write(OUTPUT_UNIT, 100) form_header('Adiabatic Discriminant Scan', '=')
100    format(A)
    endif

    n_omega = SIZE(omega)

    call partition_tasks(n_omega, 1, i_part)

    call SYSTEM_CLOCK(c_beg, c_rate)

    $if($MPI)
    call barrier()
    $endif

    discrim_loop : do i = i_part(MPI_RANK+1),i_part(MPI_RANK+2)-1

       discrim(i) = ext_real(bp%discrim(CMPLX(omega(i), KIND=WP)))

       if(check_log_level('DEBUG', MPI_RANK)) then
          write(OUTPUT_UNIT, 110) 'Eval:', omega(i), fraction(discrim(i)), exponent(discrim(i))
110       format(A,2X,E23.16,2X,F19.16,2X,I7)
       endif

    end do discrim_loop

    $if($MPI)

    recvcounts = i_part(2:)-i_part(:MPI_SIZE)
    displs = i_part(:MPI_SIZE)-1

    call allgatherv(discrim, recvcounts, displs)

    $endif

    $if($MPI)
    call barrier()
    $endif

    call SYSTEM_CLOCK(c_end)

    if(check_log_level('INFO')) then
       write(OUTPUT_UNIT, 120) 'Completed ad scan; time elapsed:', REAL(c_end-c_beg, WP)/c_rate, 's'
120    format(/A,1X,F10.3,1X,A)
    endif

    ! Scan for root brackets

    n_brack = 0

    bracket_loop : do i = 1, n_omega-1

       if(discrim(i)*discrim(i+1) <= ext_real(0._WP)) then
          n_brack = n_brack + 1
          i_brack(n_brack) = i
       end if

    end do bracket_loop

    ! Set up the bracket frequencies

    omega_a = omega(i_brack(:n_brack))
    omega_b = omega(i_brack(:n_brack)+1)

    ! Finish

    return

  end subroutine scan

end module gyre_rad_search