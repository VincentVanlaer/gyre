! Program  : gyre_input
! Purpose  : input routines
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

module gyre_input

  ! Uses

  use core_kinds
  use core_constants
  use core_order
  use core_parallel

  use gyre_base_coeffs
  use gyre_oscpar
  use gyre_numpar
  use gyre_gridpar
  use gyre_grid
  use gyre_util

  use ISO_FORTRAN_ENV

  ! No implicit typing

  implicit none

  ! Access specifiers

  private

  public :: parse_args
  public :: read_oscpar
  public :: read_numpar
  public :: read_scanpar
  public :: read_shoot_gridpar
  public :: read_recon_gridpar

contains

  subroutine parse_args (filename)

    character(LEN=:), allocatable, intent(out) :: filename

    integer :: n
    integer :: length

    ! Parse the command-line arguments

    n = COMMAND_ARGUMENT_COUNT()

    $ASSERT(n == 1,Invalid number of arguments)

    call GET_COMMAND_ARGUMENT(1, LENGTH=length)
    allocate(character(LEN=length) :: filename)

    call GET_COMMAND_ARGUMENT(1, VALUE=filename)

    ! Finish

    return

  end subroutine parse_args

!****

  subroutine read_oscpar (unit, op)

    integer, intent(in)         :: unit
    type(oscpar_t), intent(out) :: op

    integer           :: l
    character(LEN=64) :: outer_bound_type

    namelist /osc/ l, outer_bound_type

    ! Read oscillation parameters

    l = 0
    outer_bound_type = 'ZERO'

    rewind(unit)
    read(unit, NML=osc, END=900)

    ! Initialize the oscpar

    op = oscpar_t(l=l, outer_bound_type=outer_bound_type)

    ! Finish

    return

    ! Jump-in point for end-of-file

900 continue

    $ABORT(No &osc namelist in input file)

  end subroutine read_oscpar

!****

  subroutine read_numpar (unit, np)

    integer, intent(in)         :: unit
    type(numpar_t), intent(out) :: np

    integer           :: n_iter_max
    real(WP)          :: theta_ad
    character(LEN=64) :: ivp_solver_type

    namelist /num/ n_iter_max, theta_ad, ivp_solver_type

    ! Read numerical parameters

    n_iter_max = 50
    theta_ad = 0._WP

    ivp_solver_type = 'MAGNUS_GL2'

    rewind(unit)
    read(unit, NML=num, END=900)

    ! Initialize the numpar

    np = numpar_t(n_iter_max=n_iter_max, theta_ad=theta_ad, ivp_solver_type=ivp_solver_type)

    ! Finish

    return

    ! Jump-in point for end-of-file

900 continue

    $ABORT(No &num namelist in input file)

  end subroutine read_numpar

!****

  $define $READ_GRIDPAR $sub

  $local $NAME $1

  subroutine read_${NAME}_gridpar (unit, gp)

    integer, intent(in)                       :: unit
    type(gridpar_t), allocatable, intent(out) :: gp(:)

    integer            :: n_gp
    character(LEN=256) :: op_type
    real(WP)           :: alpha_osc
    real(WP)           :: alpha_exp
    real(WP)           :: s
    integer            :: n
    integer            :: i

    namelist /${NAME}_grid/ op_type, alpha_osc, alpha_exp, s, n

    ! Count the number of grid namelists

    rewind(unit)

    n_gp = 0

    count_loop : do
       read(unit, NML=${NAME}_grid, END=100)
       n_gp = n_gp + 1
    end do count_loop

100 continue

    $ASSERT(n_gp >= 1,At least one ${NAME}_grid namelist is required)

    ! Read grid parameters

    rewind(unit)

    allocate(gp(n_gp))

    read_loop : do i = 1,n_gp

       op_type = 'CREATE_CLONE'

       alpha_osc = 0._WP
       alpha_exp = 0._WP

       s = 0._WP

       n = 0

       read(unit, NML=${NAME}_grid)

       gp(i) = gridpar_t(op_type=op_type, &
                         alpha_osc=alpha_osc, alpha_exp=alpha_exp, &
                         omega_a=0._WP, omega_b=0._WP, &
                         s=s, n=n)

    end do read_loop

    ! Finish

    return

  end subroutine read_${NAME}_gridpar

  $endsub

  $READ_GRIDPAR(shoot)
  $READ_GRIDPAR(recon)

!****

  subroutine read_scanpar (unit, bc, op, gp, x_in, omega)

    integer, intent(in)                :: unit
    class(base_coeffs_t), intent(in)   :: bc
    type(oscpar_t), intent(in)         :: op
    type(gridpar_t), intent(inout)     :: gp(:)
    real(WP), allocatable, intent(in)  :: x_in(:)
    real(WP), allocatable, intent(out) :: omega(:)

    character(LEN=256) :: grid_type
    real(WP)           :: freq_min
    real(WP)           :: freq_max
    integer            :: n_freq
    character(LEN=256) :: freq_units
    real(WP)           :: x_i
    real(WP)           :: x_o
    real(WP)           :: omega_min
    real(WP)           :: omega_max
    integer            :: i

    namelist /scan/ grid_type, freq_min, freq_max, n_freq, freq_units

    ! Determine the grid range

    call grid_range(gp, bc, op, x_in, x_i, x_o)

    ! Read scan parameters

    rewind(unit)

    allocate(omega(0))

    read_loop : do 

       grid_type = 'LINEAR'

       freq_min = 1._WP
       freq_max = 10._WP
       n_freq = 10
          
       freq_units = 'NONE'

       read(unit, NML=scan, END=100)
          
       ! Set up the frequency grid

       omega_min = freq_min/freq_scale(bc, op, x_o, freq_units)
       omega_max = freq_max/freq_scale(bc, op, x_o, freq_units)
       
       select case(grid_type)
       case('LINEAR')
          omega = [omega,(((n_freq-i)*omega_min + (i-1)*omega_max)/(n_freq-1), i=1,n_freq)]
       case('INVERSE')
          omega = [omega,((n_freq-1)/((n_freq-i)/omega_min + (i-1)/omega_max), i=1,n_freq)]
       case default
          $ABORT(Invalid grid_type)
       end select

    end do read_loop

100 continue

    ! Sort the frequencies

    omega = omega(sort_indices(omega))

    ! Store the frequency range in gp

    gp%omega_a = MINVAL(omega)
    gp%omega_b = MAXVAL(omega)

    ! Finish

    return

  end subroutine read_scanpar

end module gyre_input