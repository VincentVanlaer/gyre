! Module   : gyre_tidal_context 
! Purpose  : context constructor for solving tidal equations
!
! Copyright 2022 Rich Townsend & The GYRE Team
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

module gyre_tidal_context

  ! Uses

  use core_kinds

  use gyre_context
  use gyre_model
  use gyre_grid_par
  use gyre_mode_par 
  use gyre_orbit_par
  use gyre_osc_par
  use gyre_rot_par

  use ISO_FORTRAN_ENV

  ! No implicit typing

  implicit none

  ! Interfaces

  interface context_t
     module procedure context_t_
  end interface context_t

  ! Access specifiers

  private

  public :: context_t

  ! Procedures

contains

  function context_t_ (ml, gr_p, md_p, or_p, os_p, rt_p) result (cx)

    class(model_t), pointer, intent(in) :: ml
    type(grid_par_t), intent(in)        :: gr_p
    type(mode_par_t), intent(in)        :: md_p
    type(orbit_par_t), intent(in)       :: or_p
    type(osc_par_t), intent(in)         :: os_p
    type(rot_par_t), intent(in)         :: rt_p
    type(context_t)                     :: cx

    type(rot_par_t) :: rt_p_
    real(WP)        :: scale

    ! Construct the context_t

    rt_p_ = rt_p

    select case(rt_p%Omega_rot_source)
    case ('ORBIT')

       select case(rt_p%Omega_rot_units)
       case ('SYNC')
          scale = or_p%Omega_orb
       case ('PSEUDO-SYNC')
          associate (e => or_p%e)
            scale = or_p%Omega_orb*(1 + 15*e**2/2 + 45*e**4/8 + 5*e**6/16)/ &
                                   ((1 + 3*e**2 + 3*e**4/8)*sqrt(1 - e**2)**3)
          end associate
       case default
          $ABORT(Invalid Omega_rot_units)
       end select
          
       rt_p_%Omega_rot_source = 'UNIFORM'
       rt_p_%Omega_rot = rt_p%Omega_rot*scale
       rt_p_%Omega_rot_units = or_p%Omega_orb_units

    end select
          
    cx = context_t(ml, gr_p, md_p, os_p, rt_p_)

    ! Finish

    return

  end function context_t_

end module gyre_tidal_context
