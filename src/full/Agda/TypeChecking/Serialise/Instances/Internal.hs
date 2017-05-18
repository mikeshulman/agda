{-# LANGUAGE CPP #-}

{-# OPTIONS_GHC -fno-warn-orphans #-}

module Agda.TypeChecking.Serialise.Instances.Internal where

import Control.Applicative
import Control.Monad.State.Strict

import Agda.Syntax.Internal as I
import Agda.Syntax.Position as P

import Agda.TypeChecking.Serialise.Base
import Agda.TypeChecking.Serialise.Instances.Common ()
import Agda.TypeChecking.Serialise.Instances.Compilers ()

import Agda.TypeChecking.Monad
import Agda.TypeChecking.CompiledClause
import Agda.TypeChecking.Positivity.Occurrence

import Agda.Utils.Permutation

#include "undefined.h"
import Agda.Utils.Impossible

instance EmbPrj Signature where
  icod_ (Sig a b c) = icodeN' Sig a b c

  value = value3 Sig

instance EmbPrj Section where
  icod_ (Section a) = icodeN' Section a

  value = value1 Section

instance EmbPrj a => EmbPrj (Tele a) where
  icod_ EmptyTel        = icodeN' EmptyTel
  icod_ (ExtendTel a b) = icodeN' ExtendTel a b

  value = vcase valu where
    valu []     = valuN EmptyTel
    valu [a, b] = valuN ExtendTel a b
    valu _      = malformed

instance EmbPrj Permutation where
  icod_ (Perm a b) = icodeN' Perm a b

  value = value2 Perm

instance EmbPrj a => EmbPrj (Drop a) where
  icod_ (Drop a b) = icodeN' Drop a b

  value = value2 Drop

instance EmbPrj a => EmbPrj (Elim' a) where
  icod_ (Apply a)      = icodeN' Apply a
  icod_ (IApply x y a) = icodeN 0 IApply x y a
  icod_ (Proj a b)     = icodeN 0 Proj a b

  value = vcase valu where
    valu [a]       = valuN Apply a
    valu [0,x,y,a] = valuN IApply x y a
    valu [0, a, b] = valuN Proj a b
    valu _         = malformed

instance EmbPrj I.ConHead where
  icod_ (ConHead a b c) = icodeN' ConHead a b c

  value = value3 ConHead

instance (EmbPrj a) => EmbPrj (I.Type' a) where
  icod_ (El a b) = icodeN' El a b

  value = value2 El

instance EmbPrj a => EmbPrj (I.Abs a) where
  icod_ (NoAbs a b) = icodeN 0 NoAbs a b
  icod_ (Abs a b)   = icodeN' Abs a b

  value = vcase valu where
    valu [a, b]    = valuN Abs a b
    valu [0, a, b] = valuN NoAbs a b
    valu _         = malformed

instance EmbPrj I.Term where
  icod_ (Var     a []) = icodeN' (\ a -> Var a []) a
  icod_ (Var      a b) = icodeN 0 Var a b
  icod_ (Lam      a b) = icodeN 1 Lam a b
  icod_ (Lit      a  ) = icodeN 2 Lit a
  icod_ (Def      a b) = icodeN 3 Def a b
  icod_ (Con    a b c) = icodeN 4 Con a b c
  icod_ (Pi       a b) = icodeN 5 Pi a b
  icod_ (Sort     a  ) = icodeN 7 Sort a
  icod_ (MetaV    a b) = icodeN 8 MetaV a b
  icod_ (DontCare a  ) = icodeN 9 DontCare a
  icod_ (Level    a  ) = icodeN 10 Level a
  icod_ (Shared p)     = icodeMemo termD termC p $ icode (derefPtr p)

  value r = vcase valu' r where
    valu' xs       = gets mkShared <*> valu xs
    valu [a]       = valuN var   a
    valu [0, a, b] = valuN Var   a b
    valu [1, a, b] = valuN Lam   a b
    valu [2, a]    = valuN Lit   a
    valu [3, a, b] = valuN Def   a b
    valu [4, a, b, c] = valuN Con a b c
    valu [5, a, b] = valuN Pi    a b
    valu [7, a]    = valuN Sort  a
    valu [8, a, b] = valuN MetaV a b
    valu [9, a]    = valuN DontCare a
    valu [10, a]   = valuN Level a
    valu _         = malformed

instance EmbPrj Level where
  icod_ (Max a) = icodeN' Max a

  value = value1 Max

instance EmbPrj PlusLevel where
  icod_ (ClosedLevel a) = icodeN' ClosedLevel a
  icod_ (Plus a b)      = icodeN' Plus a b

  value = vcase valu where
    valu [a]    = valuN ClosedLevel a
    valu [a, b] = valuN Plus a b
    valu _      = malformed

instance EmbPrj LevelAtom where
  icod_ (NeutralLevel r a) = icodeN' (NeutralLevel r) a
  icod_ (UnreducedLevel a) = icodeN 1 UnreducedLevel a
  icod_ (MetaLevel a b)    = icodeN 2 MetaLevel a b
  icod_ BlockedLevel{}     = __IMPOSSIBLE__

  value = vcase valu where
    valu [a]    = valuN UnreducedLevel a -- we forget that we are a NeutralLevel,
                                         -- since we do not want do (de)serialize
                                         -- the reason for neutrality
    valu [1, a] = valuN UnreducedLevel a
    valu [2, a, b] = valuN MetaLevel a b
    valu _      = malformed

instance EmbPrj I.Sort where
  icod_ (Type  a  ) = icodeN 0 Type a
  icod_ Prop        = icodeN' Prop
  icod_ SizeUniv    = icodeN 1 SizeUniv
  icod_ Inf         = icodeN 2 Inf
  icod_ (DLub a b)  = icodeN 3 DLub a b -- Andreas, 2017-01-18: not __IMPOSSIBLE__ see #2408

  value = vcase valu where
    valu []        = valuN Prop
    valu [0, a]    = valuN Type  a
    valu [1]       = valuN SizeUniv
    valu [2]       = valuN Inf
    valu [3, a, b] = valuN DLub a b
    valu _         = malformed

instance EmbPrj DisplayForm where
  icod_ (Display a b c) = icodeN' Display a b c

  value = value3 Display

instance EmbPrj a => EmbPrj (Open a) where
  icod_ (OpenThing a b) = icodeN' OpenThing a b

  value = value2 OpenThing

instance EmbPrj a => EmbPrj (Local a) where
  icod_ (Local a b) = icodeN' Local a b
  icod_ (Global a)  = icodeN' Global a

  value = vcase valu where
    valu [a, b] = valuN Local a b
    valu [a]    = valuN Global a
    valu _      = malformed

instance EmbPrj CtxId where
  icod_ (CtxId a) = icode a
  value n         = CtxId `fmap` value n

instance EmbPrj DisplayTerm where
  icod_ (DTerm    a  )   = icodeN' DTerm a
  icod_ (DDot     a  )   = icodeN 1 DDot a
  icod_ (DCon     a b c) = icodeN 2 DCon a b c
  icod_ (DDef     a b)   = icodeN 3 DDef a b
  icod_ (DWithApp a b c) = icodeN 4 DWithApp a b c

  value = vcase valu where
    valu [a]          = valuN DTerm a
    valu [1, a]       = valuN DDot a
    valu [2, a, b, c] = valuN DCon a b c
    valu [3, a, b]    = valuN DDef a b
    valu [4, a, b, c] = valuN DWithApp a b c
    valu _            = malformed

instance EmbPrj MutualId where
  icod_ (MutId a) = icode a
  value n         = MutId `fmap` value n

instance EmbPrj Definition where
  icod_ (Defn a b c d e f g h i j k l m n) = icodeN' Defn a b (P.killRange c) d e f g h i j k l m n

  value = vcase valu where
    valu [a, b, c, d, e, f, g, h, i, j, k, l, m, n] = valuN Defn a b c d e f g h i j k l m n
    valu _                                       = malformed

instance EmbPrj NLPat where
  icod_ (PVar a b c)    = icodeN 0 PVar a b c
  icod_ (PWild)         = icodeN 1 PWild
  icod_ (PDef a b)      = icodeN 2 PDef a b
  icod_ (PLam a b)      = icodeN 3 PLam a b
  icod_ (PPi a b)       = icodeN 4 PPi a b
  icod_ (PBoundVar a b) = icodeN 5 PBoundVar a b
  icod_ (PTerm a)       = icodeN 6 PTerm a

  value = vcase valu where
    valu [0, a, b, c] = valuN PVar a b c
    valu [1]          = valuN PWild
    valu [2, a, b]    = valuN PDef a b
    valu [3, a, b]    = valuN PLam a b
    valu [4, a, b]    = valuN PPi a b
    valu [5, a, b]    = valuN PBoundVar a b
    valu [6, a]       = valuN PTerm a
    valu _            = malformed

instance EmbPrj NLPType where
  icod_ (NLPType a b) = icodeN' NLPType a b

  value = value2 NLPType

instance EmbPrj RewriteRule where
  icod_ (RewriteRule a b c d e f) = icodeN' RewriteRule a b c d e f

  value = value6 RewriteRule

instance EmbPrj Projection where
  icod_ (Projection a b c d e) = icodeN' Projection a b c d e

  value = value5 Projection

instance EmbPrj ProjLams where
  icod_ (ProjLams a) = icodeN' ProjLams a

  value = value1 ProjLams

instance EmbPrj ExtLamInfo where
  icod_ (ExtLamInfo a b) = icodeN' ExtLamInfo a b

  value = value2 ExtLamInfo

instance EmbPrj Polarity where
  icod_ Covariant     = return 0
  icod_ Contravariant = return 1
  icod_ Invariant     = return 2
  icod_ Nonvariant    = return 3

  value 0 = return Covariant
  value 1 = return Contravariant
  value 2 = return Invariant
  value 3 = return Nonvariant
  value _ = malformed

instance EmbPrj Occurrence where
  icod_ StrictPos = return 0
  icod_ Mixed     = return 1
  icod_ Unused    = return 2
  icod_ GuardPos  = return 3
  icod_ JustPos   = return 4
  icod_ JustNeg   = return 5

  value 0 = return StrictPos
  value 1 = return Mixed
  value 2 = return Unused
  value 3 = return GuardPos
  value 4 = return JustPos
  value 5 = return JustNeg
  value _ = malformed

instance EmbPrj EtaEquality where
  icod_ (Specified a) = icodeN 0 Specified a
  icod_ (Inferred a)  = icodeN 1 Inferred a

  value = vcase valu where
    valu [0,a] = valuN Specified a
    valu [1,a] = valuN Inferred a
    valu _     = malformed

instance EmbPrj Defn where
  icod_ Axiom                                   = icodeN 0 Axiom
  icod_ (Function    a b t c d e f g h i j k m) =
    icodeN 1 (\ a b -> Function a b t) a b c d e f g h i j k m
  icod_ (Datatype    a b c d e f g h i j)       = icodeN 2 Datatype a b c d e f g h i j
  icod_ (Record      a b c d e f g h i j k)     = icodeN 3 Record a b c d e f g h i j k
  icod_ (Constructor a b c d e f g h)           = icodeN 4 Constructor a b c d e f g h
  icod_ (Primitive   a b c d)                   = icodeN 5 Primitive a b c d
  icod_ AbstractDefn                            = __IMPOSSIBLE__

  value = vcase valu where
    valu [0]                                     = valuN Axiom
    valu [1, a, b, c, d, e, f, g, h, i, j, k, m] = valuN (\ a b -> Function a b Nothing) a b c d e f g h i j k m
    valu [2, a, b, c, d, e, f, g, h, i, j]       = valuN Datatype a b c d e f g h i j
    valu [3, a, b, c, d, e, f, g, h, i, j, k]    = valuN Record  a b c d e f g h i j k
    valu [4, a, b, c, d, e, f, g, h]             = valuN Constructor a b c d e f g h
    valu [5, a, b, c, d]                         = valuN Primitive   a b c d
    valu _                                       = malformed

instance EmbPrj FunctionFlag where
  icod_ FunStatic       = icodeN 0 FunStatic
  icod_ FunInline       = icodeN 1 FunInline
  icod_ FunMacro        = icodeN 2 FunMacro

  value = vcase valu where
    valu [0] = valuN FunStatic
    valu [1] = valuN FunInline
    valu [2] = valuN FunMacro
    valu _   = malformed

instance EmbPrj a => EmbPrj (WithArity a) where
  icod_ (WithArity a b) = icodeN' WithArity a b

  value = value2 WithArity

instance EmbPrj a => EmbPrj (Case a) where
  icod_ (Branches a b c d e) = icodeN' Branches a b c d e

  value = value5 Branches

instance EmbPrj CompiledClauses where
  icod_ Fail       = icodeN' Fail
  icod_ (Done a b) = icodeN' Done a (P.killRange b)
  icod_ (Case a b) = icodeN 2 Case a b

  value = vcase valu where
    valu []        = valuN Fail
    valu [a, b]    = valuN Done a b
    valu [2, a, b] = valuN Case a b
    valu _         = malformed

instance EmbPrj a => EmbPrj (FunctionInverse' a) where
  icod_ NotInjective = icodeN' NotInjective
  icod_ (Inverse a)  = icodeN' Inverse a

  value = vcase valu where
    valu []  = valuN NotInjective
    valu [a] = valuN Inverse a
    valu _   = malformed

instance EmbPrj TermHead where
  icod_ SortHead     = icodeN' SortHead
  icod_ PiHead       = icodeN 1 PiHead
  icod_ (ConsHead a) = icodeN 2 ConsHead a

  value = vcase valu where
    valu []     = valuN SortHead
    valu [1]    = valuN PiHead
    valu [2, a] = valuN ConsHead a
    valu _      = malformed

instance EmbPrj I.Clause where
  icod_ (Clause a b c d e f g) = icodeN' Clause a b c d e f g

  value = value7 Clause

instance EmbPrj I.ConPatternInfo where
  icod_ (ConPatternInfo a b c) = icodeN' ConPatternInfo a b c

  value = value3 ConPatternInfo

instance EmbPrj I.DBPatVar where
  icod_ (DBPatVar a b) = icodeN' DBPatVar a b

  value = value2 DBPatVar

instance EmbPrj a => EmbPrj (I.Pattern' a) where
  icod_ (VarP a    ) = icodeN' VarP a
  icod_ (ConP a b c) = icodeN 1 ConP a b c
  icod_ (LitP a    ) = icodeN 2 LitP a
  icod_ (DotP a    ) = icodeN 3 DotP a
  icod_ (ProjP a b ) = icodeN 4 ProjP a b
  icod_ (AbsurdP a ) = icodeN 5 AbsurdP a

  value = vcase valu where
    valu [a]       = valuN VarP a
    valu [1, a, b, c] = valuN ConP a b c
    valu [2, a]    = valuN LitP a
    valu [3, a]    = valuN DotP a
    valu [4, a, b] = valuN ProjP a b
    valu [5, a]    = valuN AbsurdP a
    valu _         = malformed

instance EmbPrj a => EmbPrj (Builtin a) where
  icod_ (Prim    a) = icodeN' Prim a
  icod_ (Builtin a) = icodeN 1 Builtin a

  value = vcase valu where
    valu [a]    = valuN Prim    a
    valu [1, a] = valuN Builtin a
    valu _      = malformed

instance EmbPrj a => EmbPrj (Substitution' a) where
  icod_ IdS              = icodeN' IdS
  icod_ EmptyS           = icodeN 1 EmptyS
  icod_ (a :# b)         = icodeN 2 (:#) a b
  icod_ (Strengthen a b) = icodeN 3 Strengthen a b
  icod_ (Wk a b)         = icodeN 4 Wk a b
  icod_ (Lift a b)       = icodeN 5 Lift a b

  value = vcase valu where
    valu []        = valuN IdS
    valu [1]       = valuN EmptyS
    valu [2, a, b] = valuN (:#) a b
    valu [3, a, b]    = valuN Strengthen a b
    valu [4, a, b] = valuN Wk a b
    valu [5, a, b] = valuN Lift a b
    valu _         = malformed
