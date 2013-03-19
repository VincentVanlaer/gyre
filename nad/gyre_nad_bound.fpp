! Module   : gyre_nad_bound
! Purpose  : nonadiabatic boundary conditions
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

module gyre_nad_bound

  ! Uses

  use core_kinds

  use gyre_mech_coeffs
  use gyre_therm_coeffs
  use gyre_oscpar

  use ISO_FORTRAN_ENV

  ! No implicit typing

  implicit none

  ! Derived-type definitions

  type :: nad_bound_t
     private
     class(mech_coeffs_t), pointer  :: mc => null()
     class(therm_coeffs_t), pointer :: tc => null()
     class(oscpar_t), pointer       :: op => null()
     integer, public                :: n_e
     integer, public                :: n_i
     integer, public                :: n_o
   contains 
     private
     procedure, public :: init
     procedure, public :: inner_bound
     procedure, public :: outer_bound
     procedure, public :: outer_bound_zero
     procedure, public :: outer_bound_dziem
     procedure, public :: outer_bound_unno
     procedure, public :: outer_bound_jcd
  end type nad_bound_t

  ! Access specifiers

  private

  public :: nad_bound_t

  ! Procedures

contains

  subroutine init (this, mc, tc, op)

    class(nad_bound_t), intent(out)           :: this
    class(mech_coeffs_t), intent(in), target  :: mc
    class(therm_coeffs_t), intent(in), target :: tc
    class(oscpar_t), intent(in), target       :: op

    ! Initialize the nad_bound

    this%mc => mc
    this%tc => tc
    this%op => op

    this%n_i = 3
    this%n_o = 3
    this%n_e = this%n_i + this%n_o

    ! Finish

    return
    
  end subroutine init

!****

  function inner_bound (this, omega, x_ad) result (B_i)

    class(nad_bound_t), intent(in) :: this
    complex(WP), intent(in)        :: omega
    real(WP), intent(in), optional :: x_ad
    complex(WP)                    :: B_i(this%n_i,this%n_e)

    real(WP) :: x_ad_

    if(PRESENT(x_ad)) then
       x_ad_ = x_ad
    else
       x_ad_ = 0._WP
    endif

    ! Set the inner boundary conditions to enforce non-diverging modes

    associate(c_1 => this%mc%c_1(0._WP), V_x2 => this%tc%V_x2_0, &
              nabla => this%tc%nabla(0._WP), nabla_ad => this%tc%nabla_ad(0._WP), c_rad => this%tc%c_rad(0._WP), &
              lambda_0 => this%op%lambda_0, l => this%op%l)

      B_i(1,1) = c_1*omega**2
      B_i(1,2) = -l
      B_i(1,3) = 0._WP
      B_i(1,4) = 0._WP
      B_i(1,5) = 0._WP
      B_i(1,6) = 0._WP

      B_i(2,1) = 0._WP
      B_i(2,2) = 0._WP
      B_i(2,3) = l
      B_i(2,4) = -1._WP
      B_i(2,5) = 0._WP
      B_i(2,6) = 0._WP

      if(0._WP < x_ad_) then

          B_i(3,1) = 0._WP
          B_i(3,2) = 0._WP
          B_i(3,3) = 0._WP
          B_i(3,4) = 0._WP
          B_i(3,5) = 1._WP
          B_i(3,6) = 0._WP

       else

         B_i(3,1) = (c_1*omega**2 - l)*nabla_ad + (l-3)*nabla
         B_i(3,2) = 0._WP
         B_i(3,3) = -l*nabla_ad
         B_i(3,4) = 0._WP
         B_i(3,5) = l/V_x2
         B_i(3,6) = nabla/c_rad

      endif

    end associate

    ! Finish

    return

  end function inner_bound

!****

  function outer_bound (this, omega) result (B_o)

    class(nad_bound_t), intent(in) :: this
    complex(WP), intent(in)       :: omega
    complex(WP)                   :: B_o(this%n_o,this%n_e)

    ! Set the outer boundary conditions

    select case (this%op%outer_bound_type)
    case ('ZERO')
       B_o = this%outer_bound_zero(omega)
    case ('DZIEM')
       B_o = this%outer_bound_dziem(omega)
    case ('UNNO')
       B_o = this%outer_bound_unno(omega)
    case ('JCD')
       B_o = this%outer_bound_jcd(omega)
    case default
       $ABORT(Invalid outer_bound_type)
    end select

    ! Finish

    return

  end function outer_bound

!****

  function outer_bound_zero (this, omega) result (B_o)

    class(nad_bound_t), intent(in) :: this
    complex(WP), intent(in)       :: omega
    complex(WP)                   :: B_o(this%n_o,this%n_e)

    ! Set the outer boundary conditions, assuming delta p -> 0. The U
    ! term in the gravitational bc is required for cases where the
    ! surface density remains finite (see Cox 1980, eqn. 17.71)

    associate(V => this%mc%V(1._WP), U => this%mc%U(1._WP), &
              nabla_ad => this%tc%nabla_ad(1._WP), &
              l => this%op%l)

      B_o(1,1) = 1._WP
      B_o(1,2) = -1._WP
      B_o(1,3) = 1._WP
      B_o(1,4) = 0._WP
      B_o(1,5) = 0._WP
      B_o(1,6) = 0._WP
      
      B_o(2,1) = U
      B_o(2,2) = 0._WP
      B_o(2,3) = l + 1._WP
      B_o(2,4) = 1._WP
      B_o(2,5) = 0._WP
      B_o(2,6) = 0._WP

      B_o(3,1) = 2._WP - 4._WP*nabla_ad*V
      B_o(3,2) = 4._WP*nabla_ad*V
      B_o(3,3) = -4._WP*nabla_ad*V
      B_o(3,4) = 0._WP
      B_o(3,5) = 4._WP
      B_o(3,6) = -1._WP

    end associate

    ! Finish

    return

  end function outer_bound_zero

!****

  function outer_bound_dziem (this, omega) result (B_o)

    class(nad_bound_t), intent(in) :: this
    complex(WP), intent(in)       :: omega
    complex(WP)                   :: B_o(this%n_o,this%n_e)

    ! Set the outer boundary conditions, assuming Dziembowski's (1971)
    ! condition: d(delta p)/dr -> 0 for an isothermal atmosphere.

    associate(V => this%mc%V(1._WP), &
              nabla_ad => this%tc%nabla_ad(1._WP), &
              l => this%op%l)

      B_o(1,1) = 1 + (l*(l+1)/omega**2 - 4 - omega**2)/V
      B_o(1,2) = -1._WP
      B_o(1,3) = 1 + (l*(l+1)/omega**2 - l - 1)/V
      B_o(1,4) = 0._WP
      B_o(1,5) = 0._WP
      B_o(1,6) = 0._WP
     
      B_o(2,1) = 0._WP
      B_o(2,2) = 0._WP
      B_o(2,3) = l + 1._WP
      B_o(2,4) = 1._WP
      B_o(2,5) = 0._WP
      B_o(2,6) = 0._WP

      B_o(3,1) = 2._WP - 4._WP*nabla_ad*V
      B_o(3,2) = 4._WP*nabla_ad*V
      B_o(3,3) = -4._WP*nabla_ad*V
      B_o(3,4) = 0._WP
      B_o(3,5) = 4._WP
      B_o(3,6) = -1._WP

    end associate

    ! Finish

    return

  end function outer_bound_dziem

!****

  function outer_bound_unno (this, omega) result (B_o)

    class(nad_bound_t), intent(in) :: this
    complex(WP), intent(in)       :: omega
    complex(WP)                   :: B_o(this%n_o,this%n_e)

    complex(WP) :: lambda
    complex(WP) :: b_11
    complex(WP) :: b_12
    complex(WP) :: b_13
    complex(WP) :: b_21
    complex(WP) :: b_22
    complex(WP) :: b_23
    complex(WP) :: alpha_1
    complex(WP) :: alpha_2

    ! Set the outer boundary conditions, assuming Unno et al.'s (1989,
    ! S18.1) formulation.

    associate(V => this%mc%V(1._WP), V_g => this%mc%V(1._WP)/this%mc%Gamma_1(1._WP), &
              As => this%mc%As(1._WP), nabla_ad => this%tc%nabla_ad(1._WP), &
              l => this%op%l)

      lambda = outer_wavenumber(V_g, As, omega, l)
      
      b_11 = V_g - 3._WP
      b_12 = l*(l+1)/omega**2 - V_g
      b_13 = V_g

      b_21 = omega**2 - As
      b_22 = 1._WP + As
      b_23 = -As
    
      alpha_1 = (b_12*b_23 - b_13*(b_22+l))/((b_11+l)*(b_22+l) - b_12*b_21)
      alpha_2 = (b_21*b_13 - b_23*(b_11+l))/((b_11+l)*(b_22+l) - b_12*b_21)

      B_o(1,1) = (lambda - b_11)/b_12
      B_o(1,2) = -1._WP
      B_o(1,3) = -(alpha_1*(lambda - b_11)/b_12 - alpha_2)
      B_o(1,4) = 0._WP
      B_o(1,5) = 0._WP
      B_o(1,6) = 0._WP

      B_o(2,1) = 0._WP
      B_o(2,2) = 0._WP
      B_o(2,3) = l + 1._WP
      B_o(2,4) = 1._WP
      B_o(2,5) = 0._WP
      B_o(2,6) = 0._WP

      B_o(3,1) = 2._WP - 4._WP*nabla_ad*V
      B_o(3,2) = 4._WP*nabla_ad*V
      B_o(3,3) = -4._WP*nabla_ad*V
      B_o(3,4) = 0._WP
      B_o(3,5) = 4._WP
      B_o(3,6) = -1._WP

    end associate

    ! Finish

    return

  end function outer_bound_unno

!****

  function outer_bound_jcd (this, omega) result (B_o)

    class(nad_bound_t), intent(in) :: this
    complex(WP), intent(in)       :: omega
    complex(WP)                   :: B_o(this%n_o,this%n_e)

    complex(WP) :: lambda
    complex(WP) :: b_11
    complex(WP) :: b_12

    ! Set the outer boundary conditions, assuming
    ! Christensen-Dalsgaard's formulation (see ADIPLS documentation)

    associate(V => this%mc%V(1._WP), V_g => this%mc%V(1._WP)/this%mc%Gamma_1(1._WP), &
              As => this%mc%V(1._WP)*(1._WP-1._WP/this%mc%Gamma_1(1._WP)), &
              nabla_ad => this%tc%nabla_ad(1._WP), &
              l => this%op%l)

      lambda = outer_wavenumber(V_g, As, omega, l)
      
      b_11 = V_g - 3._WP
      b_12 = l*(l+1)/omega**2 - V_g

      if(l /= 0) then
         B_o(1,1) = (lambda - b_11)/b_12
         B_o(1,2) = -1._WP
         B_o(1,3) = 1._WP + (l*(l+1)/omega**2 - l - 1._WP)/(V_g + As)
         B_o(1,4) = 0._WP
         B_o(1,5) = 0._WP
         B_o(1,6) = 0._WP
      else
         B_o(1,1) = (lambda - b_11)/b_12
         B_o(1,2) = -1._WP
         B_o(1,3) = 1._WP
         B_o(1,4) = 0._WP
         B_o(1,5) = 0._WP
         B_o(1,6) = 0._WP
      endif

      B_o(2,1) = 0._WP
      B_o(2,2) = 0._WP
      B_o(2,3) = l + 1._WP
      B_o(2,4) = 1._WP
      B_o(2,5) = 0._WP
      B_o(2,6) = 0._WP

      B_o(3,1) = 2._WP - 4._WP*nabla_ad*V
      B_o(3,2) = 4._WP*nabla_ad*V
      B_o(3,3) = -4._WP*nabla_ad*V
      B_o(3,4) = 0._WP
      B_o(3,5) = 4._WP
      B_o(3,6) = -1._WP

    end associate

    ! Finish

    return

  end function outer_bound_jcd

!****

  function outer_wavenumber (V_g, As, omega, l) result (lambda)

    real(WP)                :: V_g
    real(WP), intent(in)    :: As
    complex(WP), intent(in) :: omega
    integer, intent(in)     :: l
    complex(WP)             :: lambda

    real(WP)    :: a
    real(WP)    :: b
    real(WP)    :: c
    real(WP)    :: omega2_c_1
    real(WP)    :: omega2_c_2
    complex(WP) :: gamma
    complex(WP) :: sgamma

    ! Calculate the wavenumber at the outer boundary

    if(AIMAG(omega) == 0._WP) then

       ! Calculate cutoff frequencies

       a = -4._WP*V_g
       b = (As - V_g + 4._WP)**2 + 4._WP*V_g*As + 4._WP*l*(l+1)
       c = -4._WP*l*(l+1)*As

       omega2_c_1 = (-b + SQRT(b**2 - 4._WP*a*c))/(2._WP*a)
       omega2_c_2 = (-b - SQRT(b**2 - 4._WP*a*c))/(2._WP*a)

       $ASSERT(omega2_c_2 > omega2_c_1,Incorrect cutoff frequency ordering)

       ! Evaluate the wavenumber

       gamma = -4._WP*V_g*(omega**2 - omega2_c_1)*(omega**2 - omega2_c_2)/omega**2

       if(REAL(omega**2) > omega2_c_2) then

          ! Acoustic waves

          lambda = 0.5_WP*((V_g + As - 2._WP) - SQRT(gamma))

       elseif(REAL(omega**2) < omega2_c_1) then

          ! Gravity waves

          lambda = 0.5_WP*((V_g + As - 2._WP) + SQRT(gamma))

       else

          ! Evanescent

          lambda = 0.5_WP*((V_g + As - 2._WP) - SQRT(gamma))

       endif

    else

       ! Evaluate the wavenumber

       gamma = (As - V_g + 4._WP)**2 + 4*(l*(l+1)/omega**2 - V_g)*(omega**2 - As)
       sgamma = SQRT(gamma)

       if(AIMAG(omega) > 0._WP) then

          ! Decaying oscillations; choose the wave with diverging
          ! energy density (see Townsend 2000b)

          if(REAL(sgamma) > 0._WP) then
             lambda = 0.5_WP*((V_g + As - 2._WP) + sgamma)
          else
             lambda = 0.5_WP*((V_g + As - 2._WP) - sgamma)
          endif

       else

          ! Growing oscillations; choose the wave with non-diverging
          ! energy density (see Townsend 2000b)

          if(REAL(sgamma) > 0._WP) then
             lambda = 0.5_WP*((V_g + As - 2._WP) - sgamma)
          else
             lambda = 0.5_WP*((V_g + As - 2._WP) + sgamma)
          endif

       endif

    end if

    ! Finish

    return

  end function outer_wavenumber

end module gyre_nad_bound
