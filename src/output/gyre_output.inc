! Incfile  : gyre_output
! Purpose  : macros for output module
!
! Copyright 2017-2022 Rich Townsend
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

$define $OUTPUT_WAVES $sub

$local $T $1
$local $NAME $2
$local $FUNC $3
 
case ($str($NAME))

   do i_wv = 1, n_wv
      data_$T(i_wv) = wv(i_wv)%$FUNC
   end do
   
   call wr%write($str($NAME), data_$T)

$endsub

$define $OUTPUT_POINTS $sub

$local $T $1
$local $NAME $2
$local $VAR $3
$local $FUNC $4
 
case ($str($NAME))

   do p = 1, gr%n_p
      data_$T(p) = $VAR%$FUNC
   end do
   
   call wr%write($str($NAME), data_$T)

$endsub

$define $OUTPUT_REF $sub

$local $NAME $1
$local $FUNC $2
 
case ($str($NAME))

   call wr%write($str($NAME), wv%$FUNC(wv%p_ref))

$endsub

