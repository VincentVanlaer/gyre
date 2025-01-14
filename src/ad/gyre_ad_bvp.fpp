! Module   : gyre_ad_bvp
! Purpose  : adiabatic bounary value problem solver
!
! Copyright 2013-2022 Rich Townsend
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

module gyre_ad_bvp

  ! Uses

  use core_kinds

  use gyre_ad_bound
  use gyre_ad_diff
  use gyre_ad_eqns
  use gyre_ad_trans
  use gyre_bvp
  use gyre_context
  use gyre_ext
  use gyre_grid
  use gyre_grid_factory
  use gyre_interp
  use gyre_model
  use gyre_mode_par
  use gyre_num_par
  use gyre_osc_par
  use gyre_point
  use gyre_qad_eval
  use gyre_state
  use gyre_wave

  use ISO_FORTRAN_ENV

  ! No implicit typing

  implicit none

  ! Derived-type definitions

  type, extends (r_bvp_t) :: ad_bvp_t
     private
     type(context_t), pointer :: cx => null()
     type(ad_trans_t)         :: tr
     type(grid_t)             :: gr
     type(qad_eval_t)         :: qe
     type(mode_par_t)         :: md_p
     type(num_par_t)          :: nm_p
     type(osc_par_t)          :: os_p
  end type ad_bvp_t

  ! Interfaces

  interface ad_bvp_t
     module procedure ad_bvp_t_
  end interface ad_bvp_t

  interface wave_t
     module procedure wave_t_hom_
     module procedure wave_t_inhom_
  end interface wave_t

  ! Access specifiers

  private

  public :: ad_bvp_t
  public :: wave_t

  ! Procedures

contains

  function ad_bvp_t_ (cx, gr, md_p, nm_p, os_p) result (bp)

    type(context_t), pointer, intent(in) :: cx
    type(grid_t), intent(in)             :: gr
    type(mode_par_t), intent(in)         :: md_p
    type(num_par_t), intent(in)          :: nm_p
    type(osc_par_t), intent(in)          :: os_p
    type(ad_bvp_t)                       :: bp

    type(ad_bound_t)             :: bd
    integer                      :: j
    type(ad_diff_t), allocatable :: df(:)
    type(osc_par_t)              :: qad_os_p

    ! Construct the ad_bvp_t

    ! Initialize the boundary conditions

    bd = ad_bound_t(cx, md_p, os_p)

    ! Initialize the difference equations

    allocate(df(gr%n-1))

    !$OMP PARALLEL DO
    do j = 1, gr%n-1
       df(j) = ad_diff_t(cx, gr%pt(j), gr%pt(j+1), md_p, nm_p, os_p)
    end do

    ! Initialize the bvp_t

    bp%r_bvp_t = r_bvp_t(bd, df, nm_p)

    ! Other initializations

    bp%cx => cx
    bp%gr = gr

    bp%tr = ad_trans_t(cx, md_p, os_p)
    call bp%tr%stencil(gr%pt)

    if (os_p%quasiad_eigfuncs) then
       qad_os_p = os_p
       qad_os_p%variables_set = 'GYRE'
       bp%qe = qad_eval_t(cx, gr, md_p, qad_os_p)
    endif

    bp%md_p = md_p
    bp%nm_p = nm_p
    bp%os_p = os_p

    ! Finish

    return

  end function ad_bvp_t_

  !****

  function wave_t_hom_ (bp, st, id) result (wv)

    class(ad_bvp_t), intent(inout) :: bp
    type(r_state_t), intent(in)    :: st
    integer, intent(in)            :: id
    type(wave_t)                   :: wv

    real(WP) :: y(4,bp%n)
    integer  :: j

    ! Calculate the homogeneous solution vector

    call bp%build(st)
    call bp%factor()

    y = bp%soln_vec_hom()

    ! Convert to canonical form

    !$OMP PARALLEL DO
    do j = 1, bp%n
       call bp%tr%trans_vars(y(:,j), j, st, from=.FALSE.)
    end do

    ! Construct the wave_t

    wv = wave_t_y_(bp, st, y, id)

    ! Finish

    return

  end function wave_t_hom_

  !****

  function wave_t_inhom_ (bp, st, z_i, z_o, id) result (wv)

    class(ad_bvp_t), intent(inout) :: bp
    type(r_state_t), intent(in)    :: st
    real(WP), intent(in)           :: z_i(:)
    real(WP), intent(in)           :: z_o(:)
    integer, intent(in)            :: id
    type(wave_t)                   :: wv

    real(WP) :: y(4,bp%n)
    integer  :: j

    $CHECK_BOUNDS(SIZE(z_i),bp%n_i)
    $CHECK_BOUNDS(SIZE(z_o),bp%n_o)

    ! Calculate the inhomogeneous solution vector

    call bp%build(st)
    call bp%factor()

    y = bp%soln_vec_inhom(z_i, z_o)

    ! Convert to canonical form

    !$OMP PARALLEL DO
    do j = 1, bp%n
       call bp%tr%trans_vars(y(:,j), j, st, from=.FALSE.)
    end do

    ! Construct the wave_t

    wv = wave_t_y_(bp, st, y, id)

    ! Finish

    return

  end function wave_t_inhom_

  !****

  function wave_t_y_ (bp, st, y, id) result (wv)

    class(ad_bvp_t), intent(inout) :: bp
    type(r_state_t), intent(in)    :: st
    real(WP), intent(in)           :: y(:,:)
    integer, intent(in)            :: id
    type(wave_t)                   :: wv

    type(c_state_t) :: st_c
    complex(WP)     :: y_c(6,bp%n)
    type(c_ext_t)   :: discrim

    $CHECK_BOUNDS(SIZE(y, 1),bp%n_e)
    $CHECK_BOUNDS(SIZE(y, 2),bp%n)

    ! Set up complex eigenfunctions

    st_c = c_state_t(CMPLX(st%omega, KIND=WP), st%omega)

    if (bp%os_p%quasiad_eigfuncs) then

       y_c = bp%qe%y_qad(st_c, y)

    else

       y_c(1:4,:) = y
       y_c(5:6,:) = 0._WP

    endif

    ! Construct the wave_t

    discrim = c_ext_t(bp%det())

    wv = wave_t(st_c, y_c, discrim, bp%cx, bp%gr, bp%md_p, bp%nm_p, bp%os_p, id)

    ! Finish

    return

  end function wave_t_y_

end module gyre_ad_bvp
