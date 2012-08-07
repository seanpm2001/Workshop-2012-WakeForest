--*- coding: utf-8 -*-
---------------------------------------------------------------------------
--
-- PURPOSE: Computations with convex polyhedra 
-- PROGRAMMER : Nathan Ilten 
-- UPDATE HISTORY : August 2012 
---------------------------------------------------------------------------
newPackage("VeryNewPolyhedra",
    Headline => "A package for computations with convex polyhedra",
    Version => ".1",
    Date => "August 5, 2011",
    Authors => {
         {Name => "Nathan Ilten",
	  HomePage => "http://math.berkeley.edu/~nilten",
	  Email => "nilten@math.berkeley.edu"}},
    DebuggingMode => true
    )

---------------------------------------------------------------------------
-- COPYRIGHT NOTICE:
--
-- Copyright 2012 Nathan Ilten
-- Some parts copyright 2010 Rene Birkner
--
--
-- This program is free software: you can redistribute it and/or modify
-- it under the terms of the GNU General Public License as published by
-- the Free Software Foundation, either version 3 of the License, or
-- (at your option) any later version.
--
-- This program is distributed in the hope that it will be useful,
-- but WITHOUT ANY WARRANTY; without even the implied warranty of
-- MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
-- GNU General Public License for more details.
--
-- You should have received a copy of the GNU General Public License
-- along with this program.  If not, see <http://www.gnu.org/licenses/>.
--
---------------------------------------------------------------------------


export {
	"intersection",
	"linSpace",
	"vertices",
	"rays",
	"ambDim",
	"hyperplanes",
	"halfspaces",
	"PolyhedralObject", 
	"Cone", 
	"convexHull", 
	"posHull"}
	
needsPackage "FourierMotzkin"



-- Defining the new type PolyhedralObject
PolyhedralObject = new Type of MutableHashTable
globalAssignment PolyhedralObject

-- Defining the new type Polyhedron
Polyhedron = new Type of PolyhedralObject
Polyhedron.synonym = "convex polyhedron"
globalAssignment Polyhedron

-- Defining the new type Cone
Cone = new Type of PolyhedralObject
Cone.synonym = "convex rational cone"
globalAssignment Cone

-- Defining the new type Fan
Fan = new Type of PolyhedralObject
globalAssignment Fan

-- Defining the new type PolyhedralComplex
PolyhedralComplex = new Type of PolyhedralObject
globalAssignment PolyhedralObject


convexHull = method()
convexHull (Matrix,Matrix,Matrix):=(M,N,L)->(
     new Polyhedron from hashTable {
	  "Points"=>promote(homCoordinates(transpose M,transpose N),QQ),
     	  "InputLineality"=>promote(homRays(transpose L),QQ)}
     )

convexHull (Matrix,Matrix):=(M,N)->(convexHull(M,N,map(QQ^(numRows M),QQ^0,0)))
     
convexHull Matrix :=M->(convexHull(M,map(QQ^(numRows M),QQ^0,0)))

convexHull (Polyhedron,Polyhedron):=(P1,P2)->convexHull {P1,P2}

convexHull List := L->(
   datalist:=apply(L,P->(
       if instance(P,Polyhedron) then (
	    if not P#?"Points" and not P#?"Vertices" then computeRays P;
	    if P#?"Vertices" then return(P#"Vertices",P#"LinealitySpace");
	    return (P#"Points",P#"InputLineality")
	    )
       else if instance(P,Cone) then (
	    if not P#?"InputRays" and not P#?"Rays" then computeRays P;
	    if P#?"Rays" then return(homRays P#"Rays",homRays P#"LinealitySpace");
	    return (homRays P#"InputRays",homRays P#"InputLineality")	   
    	   )
	else if instance(P,Matrix) then (
	     return (homPoints transpose promote(P,QQ),transpose map(QQ^(1+numRows P),QQ^0,0))
		    )
	      else return (promote(homCoordinates(transpose P#0,transpose P#1),QQ),
		   transpose map(QQ^(1+numRows P),QQ^0,0))));
    vlist:=matrix apply(datalist,i->{i#0});
    llist:=matrix apply(datalist,i->{i#1});
    new Polyhedron from hashTable {
	  "Points"=>vlist,
     	  "InputLineality"=>llist})


posHull = method()
posHull (Matrix, Matrix):= (M,N)-> (
     new Cone from hashTable {
	  "InputLineality"=>promote(transpose N,QQ),
  	  "InputRays"=>promote(transpose M,QQ)}
     )

posHull Matrix:=M ->(posHull(M,map(QQ^(numRows M),QQ^0,0)))


intersection = method()
intersection (Matrix,Matrix):=(M,N)->(
     new Cone from hashTable {
	  "Equations"=>promote(- N,QQ),
  	  "Inequalities"=>promote(- M,QQ)}
     )	  

intersection Matrix:=M->(intersection(M,map(QQ^0,QQ^(numColumns M),0)))




hyperplanes = method()
hyperplanes Cone := P -> (
	if P#?"Facets" then return P#"LinearSpan";
	computeFacets P;
	P#"LinearSpan")

hyperplanes Polyhedron := P -> (
	if not P#?"Facets" then computeFacets P;
	M:=P#"LinearSpan";
	(-M_(toList(1..numColumns M-1)),M_{0})
	)


halfspaces = method()
halfspaces Cone := P -> (
	if P#?"Facets" then return -P#"Facets";
	computeFacets P;
	-P#"Facets")
   
halfspaces Polyhedron := P -> (
	if not P#?"Facets" then computeFacets P;
	M:=P#"Facets";
	(-M_(toList(1..numColumns M-1)),M_{0})
	)



rays = method()
rays Cone := P -> (
	if P#?"Rays" then return transpose P#"Rays";
	computeRays P;
	transpose P#"Rays")
   
rays Polyhedron := P -> (
	if not P#?"Vertices" then computeRays P;
	transpose (dehomCoordinates P#"Vertices")_1)   

vertices = method()
vertices Polyhedron := P -> (
	if not P#?"Vertices" then computeRays P;
	transpose (dehomCoordinates P#"Vertices")_0)   

linSpace = method()
linSpace Cone := P -> (
	if P#?"Rays" then return transpose P#"LinealitySpace";
	computeRays P;
	transpose P#"LinealitySpace")
   

linSpace Polyhedron := P -> (
	if P#?"Vertices" then return transpose P#"LinealitySpace";
	computeRays P;
	transpose P#"LinealitySpace")






--Non-exported stuff

--rows are coordinates as in Polymake
homCoordinates=(M,N)->((map(QQ^(numRows M),QQ^1,(i,j)->1)|M)||(map(QQ^(numRows N),QQ^1,0)|N))
homRays=(N)->(map(QQ^(numRows N),QQ^1,0)|N)
homPoints=(N)->(map(QQ^(numRows N),QQ^1,1)|N)
--makes first coordinate 1 or 0
normalizeCoordinates=M->transpose matrix {apply(numRows M,i->(v:=(transpose M)_{i};
	  if v_(0,0)==0 then return  v;
	  ((1/(v_(0,0)))*v)))}
--assume that coordinates are normalized
dehomCoordinates=M->(
     MT:=transpose M;
     DM:=transpose (M_(toList(1..numColumns M-1)));
     verticesp:=select(numRows M,i->(MT_{i})_(0,0)==1);
     raysp:=select(numRows M,i->(MT_{i})_(0,0)==0);
     (transpose DM_verticesp,transpose DM_raysp))


computeFacets = method ()
computeFacets Cone := C -> (
     local fm;
     if not C#?"Rays" and not C#?"InputRays" then computeRays C;
     if C#?"Rays" then fm=fourierMotzkin(transpose  C#"Rays",transpose C#"LinealitySpace")
     else fm=fourierMotzkin(transpose  C#"InputRays",transpose C#"InputLineality");
     C#"Facets"=-transpose fm_0;
     C#"LinearSpan"=-transpose fm_1;
     )
     
computeFacets Polyhedron :=C->(
     local fm;
     if not C#?"Vertices" and not C#?"Points" then computeRays C;     
     if C#?"Vertices" then fm=fourierMotzkin(transpose  C#"Vertices",transpose C#"LinealitySpace")
     else fm=fourierMotzkin(transpose  C#"Points",transpose C#"InputLineality");
     C#"Facets"=-transpose fm_0;
     C#"LinearSpan"=-transpose fm_1;     
     )

computeRays = method ()
computeRays Cone := C -> (
     local fm;
     if not C#?"Facets" and not C#?"Inequalities" then computeFacets C;
     if C#?"Facets" then fm=fourierMotzkin(transpose C#"Facets",transpose C#"LinearSpan")
     else fm=fourierMotzkin(transpose C#"Inequalities",transpose C#"Equations");
     C#"Rays"=-transpose fm_0;
     C#"LinealitySpace"=-transpose fm_1;
     )

computeRays Polyhedron := C -> (
     local fm;
     if not C#?"Facets" and not C#?"Inequalities" then computeFacets C;
     if C#?"Facets" then fm=fourierMotzkin(transpose C#"Facets",transpose C#"LinearSpan")
     else fm=fourierMotzkin(transpose C#"Inequalities",transpose C#"Equations");
     C#"Vertices"=normalizeCoordinates (-transpose fm_0);
     C#"LinealitySpace"=-transpose fm_1;
     )






beginDocumentation()
