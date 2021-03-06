{-# LANGUAGE RankNTypes, ScopedTypeVariables, PatternGuards #-}

module Idris.Primitives(primitives, Prim(..)) where

import Idris.AbsSyntax

import IRTS.Lang

import Core.TT
import Core.Evaluate
import Data.Bits
import Data.Word
import Data.Int
import Data.Char
import Data.Function (on)
import Data.Vector.Unboxed (Vector)
import qualified Data.Vector.Unboxed as V

data Prim = Prim { p_name  :: Name,
                   p_type  :: Type,
                   p_arity :: Int,
                   p_def   :: [Const] -> Maybe Const,
		   p_lexp  :: (Int, PrimFn),
                   p_total :: Totality
                 }

ty :: [Const] -> Const -> Type
ty []     x = Constant x
ty (t:ts) x = Bind (MN 0 "T") (Pi (Constant t)) (ty ts x)

total, partial :: Totality
total = Total []
partial = Partial NotCovering

primitives :: [Prim]
primitives =
   -- operators
  [iCoerce (ITFixed IT8) (ITFixed IT16) "zext" zext LZExt,
   iCoerce (ITFixed IT8) (ITFixed IT32) "zext" zext LZExt,
   iCoerce (ITFixed IT8) (ITFixed IT64) "zext" zext LZExt,
   iCoerce (ITFixed IT8) ITBig "zext" zext LZExt,
   iCoerce (ITFixed IT8) ITNative "zext" zext LZExt,
   iCoerce (ITFixed IT16) (ITFixed IT32) "zext" zext LZExt,
   iCoerce (ITFixed IT16) (ITFixed IT64) "zext" zext LZExt,
   iCoerce (ITFixed IT16) ITBig "zext" zext LZExt,
   iCoerce (ITFixed IT16) ITNative "zext" zext LZExt,
   iCoerce (ITFixed IT32) (ITFixed IT64) "zext" zext LZExt,
   iCoerce (ITFixed IT32) ITBig "zext" zext LZExt,
   iCoerce (ITFixed IT32) ITNative "zext" zext LZExt,
   iCoerce (ITFixed IT64) ITBig "zext" zext LZExt,
   iCoerce ITNative ITBig "zext" zext LZExt,
   iCoerce ITNative (ITFixed IT64) "zext" zext LZExt,
   iCoerce ITNative (ITFixed IT32) "zext" zext LZExt,
   iCoerce ITNative (ITFixed IT16) "zext" zext LZExt,
   iCoerce ITChar ITBig "zext" zext LZExt,

   iCoerce (ITFixed IT8) (ITFixed IT16) "sext" sext LSExt,
   iCoerce (ITFixed IT8) (ITFixed IT32) "sext" sext LSExt,
   iCoerce (ITFixed IT8) (ITFixed IT64) "sext" sext LSExt,
   iCoerce (ITFixed IT8) ITBig "sext" sext LSExt,
   iCoerce (ITFixed IT8) ITNative "sext" sext LSExt,
   iCoerce (ITFixed IT16) (ITFixed IT32) "sext" sext LSExt,
   iCoerce (ITFixed IT16) (ITFixed IT64) "sext" sext LSExt,
   iCoerce (ITFixed IT16) ITBig "sext" sext LSExt,
   iCoerce (ITFixed IT16) ITNative "sext" sext LSExt,
   iCoerce (ITFixed IT32) (ITFixed IT64) "sext" sext LSExt,
   iCoerce (ITFixed IT32) ITBig "sext" sext LSExt,
   iCoerce (ITFixed IT32) ITNative "sext" sext LSExt,
   iCoerce (ITFixed IT64) ITBig "sext" sext LSExt,
   iCoerce ITNative ITBig "sext" sext LSExt,
   iCoerce ITNative ITBig "sext" sext LSExt,
   iCoerce ITNative (ITFixed IT64) "sext" sext LSExt,
   iCoerce ITNative (ITFixed IT32) "sext" sext LSExt,
   iCoerce ITNative (ITFixed IT16) "sext" sext LSExt,
   iCoerce ITChar ITBig "sext" sext LSExt,

   iCoerce (ITFixed IT16) (ITFixed IT8) "trunc" trunc LTrunc,
   iCoerce (ITFixed IT32) (ITFixed IT8) "trunc" trunc LTrunc,
   iCoerce (ITFixed IT64) (ITFixed IT8) "trunc" trunc LTrunc,
   iCoerce ITBig (ITFixed IT8) "trunc" trunc LTrunc,
   iCoerce ITNative (ITFixed IT8) "trunc" trunc LTrunc,
   iCoerce (ITFixed IT32) (ITFixed IT16) "trunc" trunc LTrunc,
   iCoerce (ITFixed IT64) (ITFixed IT16) "trunc" trunc LTrunc,
   iCoerce ITBig (ITFixed IT16) "trunc" trunc LTrunc,
   iCoerce ITNative (ITFixed IT16) "trunc" trunc LTrunc,
   iCoerce (ITFixed IT64) (ITFixed IT32) "trunc" trunc LTrunc,
   iCoerce ITBig (ITFixed IT32) "trunc" trunc LTrunc,
   iCoerce ITNative (ITFixed IT32) "trunc" trunc LTrunc,
   iCoerce ITBig (ITFixed IT64) "trunc" trunc LTrunc,
   iCoerce (ITFixed IT16) ITNative "trunc" trunc LTrunc,
   iCoerce (ITFixed IT32) ITNative "trunc" trunc LTrunc,
   iCoerce (ITFixed IT64) ITNative "trunc" trunc LTrunc,
   iCoerce ITBig ITNative "trunc" trunc LTrunc,
   iCoerce ITNative (ITFixed IT64) "trunc" trunc LTrunc,
   iCoerce ITBig ITChar "trunc" trunc LTrunc,

   Prim (UN "prim__addFloat") (ty [(AType ATFloat), (AType ATFloat)] (AType ATFloat)) 2 (fBin (+))
     (2, LPlus ATFloat) total,
   Prim (UN "prim__subFloat") (ty [(AType ATFloat), (AType ATFloat)] (AType ATFloat)) 2 (fBin (-))
     (2, LMinus ATFloat) total,
   Prim (UN "prim__mulFloat") (ty [(AType ATFloat), (AType ATFloat)] (AType ATFloat)) 2 (fBin (*))
     (2, LTimes ATFloat) total,
   Prim (UN "prim__divFloat") (ty [(AType ATFloat), (AType ATFloat)] (AType ATFloat)) 2 (fBin (/))
     (2, LSDiv ATFloat) total,
   Prim (UN "prim__eqFloat")  (ty [(AType ATFloat), (AType ATFloat)] (AType (ATInt ITNative))) 2 (bfBin (==))
     (2, LEq ATFloat) total,
   Prim (UN "prim__sltFloat")  (ty [(AType ATFloat), (AType ATFloat)] (AType (ATInt ITNative))) 2 (bfBin (<))
     (2, LSLt ATFloat) total,
   Prim (UN "prim__slteFloat") (ty [(AType ATFloat), (AType ATFloat)] (AType (ATInt ITNative))) 2 (bfBin (<=))
     (2, LSLe ATFloat) total,
   Prim (UN "prim__sgtFloat")  (ty [(AType ATFloat), (AType ATFloat)] (AType (ATInt ITNative))) 2 (bfBin (>))
     (2, LSGt ATFloat) total,
   Prim (UN "prim__sgteFloat") (ty [(AType ATFloat), (AType ATFloat)] (AType (ATInt ITNative))) 2 (bfBin (>=))
     (2, LSGe ATFloat) total,
   Prim (UN "prim__concat") (ty [StrType, StrType] StrType) 2 (sBin (++))
    (2, LStrConcat) total,
   Prim (UN "prim__eqString") (ty [StrType, StrType] (AType (ATInt ITNative))) 2 (bsBin (==))
    (2, LStrEq) total,
   Prim (UN "prim__ltString") (ty [StrType, StrType] (AType (ATInt ITNative))) 2 (bsBin (<))
    (2, LStrLt) total,
   Prim (UN "prim_lenString") (ty [StrType] (AType (ATInt ITNative))) 1 (p_strLen)
    (1, LStrLen) total,
    -- Conversions
   Prim (UN "prim__charToInt") (ty [(AType (ATInt ITChar))] (AType (ATInt ITNative))) 1 (c_charToInt)
     (1, LChInt ITNative) total,
   Prim (UN "prim__intToChar") (ty [(AType (ATInt ITNative))] (AType (ATInt ITChar))) 1 (c_intToChar)
     (1, LIntCh ITNative) total,
   Prim (UN "prim__strToFloat") (ty [StrType] (AType ATFloat)) 1 (c_strToFloat)
     (1, LStrFloat) total,
   Prim (UN "prim__floatToStr") (ty [(AType ATFloat)] StrType) 1 (c_floatToStr)
     (1, LFloatStr) total,

   Prim (UN "prim__floatExp") (ty [(AType ATFloat)] (AType ATFloat)) 1 (p_floatExp)
     (1, LFExp) total,
   Prim (UN "prim__floatLog") (ty [(AType ATFloat)] (AType ATFloat)) 1 (p_floatLog)
     (1, LFLog) total,
   Prim (UN "prim__floatSin") (ty [(AType ATFloat)] (AType ATFloat)) 1 (p_floatSin)
     (1, LFSin) total,
   Prim (UN "prim__floatCos") (ty [(AType ATFloat)] (AType ATFloat)) 1 (p_floatCos)
     (1, LFCos) total,
   Prim (UN "prim__floatTan") (ty [(AType ATFloat)] (AType ATFloat)) 1 (p_floatTan)
     (1, LFTan) total,
   Prim (UN "prim__floatASin") (ty [(AType ATFloat)] (AType ATFloat)) 1 (p_floatASin)
     (1, LFASin) total,
   Prim (UN "prim__floatACos") (ty [(AType ATFloat)] (AType ATFloat)) 1 (p_floatACos)
     (1, LFACos) total,
   Prim (UN "prim__floatATan") (ty [(AType ATFloat)] (AType ATFloat)) 1 (p_floatATan)
     (1, LFATan) total,
   Prim (UN "prim__floatSqrt") (ty [(AType ATFloat)] (AType ATFloat)) 1 (p_floatSqrt)
     (1, LFSqrt) total,
   Prim (UN "prim__floatFloor") (ty [(AType ATFloat)] (AType ATFloat)) 1 (p_floatFloor)
     (1, LFFloor) total,
   Prim (UN "prim__floatCeil") (ty [(AType ATFloat)] (AType ATFloat)) 1 (p_floatCeil)
     (1, LFCeil) total,

   Prim (UN "prim__strHead") (ty [StrType] (AType (ATInt ITChar))) 1 (p_strHead)
     (1, LStrHead) partial,
   Prim (UN "prim__strTail") (ty [StrType] StrType) 1 (p_strTail)
     (1, LStrTail) partial,
   Prim (UN "prim__strCons") (ty [(AType (ATInt ITChar)), StrType] StrType) 2 (p_strCons)
    (2, LStrCons) total,
   Prim (UN "prim__strIndex") (ty [StrType, (AType (ATInt ITNative))] (AType (ATInt ITChar))) 2 (p_strIndex)
    (2, LStrIndex) partial,
   Prim (UN "prim__strRev") (ty [StrType] StrType) 1 (p_strRev)
    (1, LStrRev) total,
   Prim (UN "prim__readString") (ty [PtrType] StrType) 1 (p_cantreduce)
     (1, LReadStr) partial,
   Prim (UN "prim__vm") (ty [] PtrType) 0 (p_cantreduce)
     (0, LVMPtr) total,
   -- Streams
   Prim (UN "prim__stdin") (ty [] PtrType) 0 (p_cantreduce)
    (0, LStdIn) partial,
   Prim (UN "prim__null") (ty [] PtrType) 0 (p_cantreduce)
    (0, LNullPtr) total
  ] ++ concatMap intOps [ITFixed IT8, ITFixed IT16, ITFixed IT32, ITFixed IT64, ITBig, ITNative, ITChar]
    ++ concatMap vecOps vecTypes
    ++ vecBitcasts vecTypes

vecTypes :: [IntTy]
vecTypes = [ITVec IT8 16, ITVec IT16 8, ITVec IT32 4, ITVec IT64 2]

intOps :: IntTy -> [Prim]
intOps ity = intCmps ity ++ intArith ity ++ intConv ity

intSCmps :: IntTy -> [Prim]
intSCmps ity =
    [ iCmp ity "slt" False (bCmp ity (sCmpOp ity (<))) (LSLt . ATInt) total
    , iCmp ity "slte" False (bCmp ity (sCmpOp ity (<=))) (LSLe . ATInt) total
    , iCmp ity "eq" False (bCmp ity (==)) (LEq . ATInt) total
    , iCmp ity "sgte" False (bCmp ity (sCmpOp ity (>=))) (LSGe . ATInt) total
    , iCmp ity "sgt" False (bCmp ity (sCmpOp ity (>))) (LSGt . ATInt) total
    ]

intCmps :: IntTy -> [Prim]
intCmps ITNative = intSCmps ITNative
intCmps ity =
    intSCmps ity ++
    [ iCmp ity "lt" False (bCmp ity (cmpOp ity (<))) LLt total
    , iCmp ity "lte" False (bCmp ity (cmpOp ity (<=))) LLe total
    , iCmp ity "gte" False (bCmp ity (cmpOp ity (>=))) LGe total
    , iCmp ity "gt" False (bCmp ity (cmpOp ity (>))) LGt total
    ]

intArith :: IntTy -> [Prim]
intArith ity =
    [ iBinOp ity "add" (bitBin ity (+)) (LPlus . ATInt) total
    , iBinOp ity "sub" (bitBin ity (-)) (LMinus . ATInt) total
    , iBinOp ity "mul" (bitBin ity (*)) (LTimes . ATInt) total
    , iBinOp ity "udiv" (bitBin ity div) LUDiv partial
    , iBinOp ity "sdiv" (bsdiv ity) (LSDiv . ATInt) partial
    , iBinOp ity "urem" (bitBin ity rem) LURem partial
    , iBinOp ity "srem" (bsrem ity) (LSRem . ATInt) partial
    , iBinOp ity "shl" (bitBin ity (\x y -> shiftL x (fromIntegral y))) LSHL total
    , iBinOp ity "lshr" (bitBin ity (\x y -> shiftR x (fromIntegral y))) LLSHR total
    , iBinOp ity "ashr" (bashr ity) LASHR total
    , iBinOp ity "and" (bitBin ity (.&.)) LAnd total
    , iBinOp ity "or" (bitBin ity (.|.)) LOr total
    , iBinOp ity "xor" (bitBin ity (xor)) LXOr total
    , iUnOp ity "compl" (bUn ity complement) LCompl total
    ]

intConv :: IntTy -> [Prim]
intConv ity =
    [ Prim (UN $ "prim__toStr" ++ intTyName ity) (ty [AType . ATInt $ ity] StrType) 1 intToStr
               (1, LIntStr ity) total
    , Prim (UN $ "prim__fromStr" ++ intTyName ity) (ty [StrType] (AType . ATInt $ ity)) 1 (strToInt ity)
               (1, LStrInt ity) total
    , Prim (UN $ "prim__toFloat" ++ intTyName ity) (ty [AType . ATInt $ ity] (AType ATFloat)) 1 intToFloat
               (1, LIntFloat ity) total
    , Prim (UN $ "prim__fromFloat" ++ intTyName ity) (ty [AType ATFloat] (AType . ATInt $ ity)) 1 (floatToInt ity)
               (1, LFloatInt ity) total
    ]

vecCmps :: IntTy -> [Prim]
vecCmps ity =
    [ iCmp ity "slt" True (bCmp ity (<)) (LSLt . ATInt) total
    , iCmp ity "slte" True (bCmp ity (<=)) (LSLe . ATInt) total
    , iCmp ity "eq" True (bCmp ity (==)) (LEq . ATInt) total
    , iCmp ity "sgte" True (bCmp ity (>=)) (LSGe . ATInt) total
    , iCmp ity "sgt" True (bCmp ity (>)) (LSGt . ATInt) total
    , iCmp ity "lt" True (bCmp ity (<)) LLt total
    , iCmp ity "lte" True (bCmp ity (<=)) LLe total
    , iCmp ity "gte" True (bCmp ity (>=)) LGe total
    , iCmp ity "gt" True (bCmp ity (>)) LGt total
    ]

vecOps :: IntTy -> [Prim]
vecOps ity@(ITVec elem count) =
    [ Prim (UN $ "prim__mk" ++ intTyName ity)
               (ty (replicate count . AType . ATInt . ITFixed $ elem) (AType . ATInt $ ity))
               count (mkVecCon elem count) (count, LMkVec elem count) total
    , Prim (UN $ "prim__index" ++ intTyName ity)
               (ty [AType . ATInt $ ity, AType (ATInt (ITFixed IT32))] (AType . ATInt . ITFixed $ elem))
               2 (mkVecIndex count) (2, LIdxVec elem count) partial -- TODO: Ensure this reduces
    , Prim (UN $ "prim__update" ++ intTyName ity)
               (ty [AType . ATInt $ ity, AType (ATInt (ITFixed IT32)), AType . ATInt . ITFixed $ elem]
                       (AType . ATInt $ ity))
               3 (mkVecUpdate elem count) (3, LUpdateVec elem count) partial -- TODO: Ensure this reduces
    ] ++ intArith ity ++ vecCmps ity

bitcastPrim :: ArithTy -> ArithTy -> (ArithTy -> [Const] -> Maybe Const) -> PrimFn -> Prim
bitcastPrim from to impl prim =
    Prim (UN $ "prim__bitcast" ++ aTyName from ++ "_" ++ aTyName to) (ty [AType from] (AType to)) 1 (impl to)
         (1, prim) total

vecBitcasts :: [IntTy] -> [Prim]
vecBitcasts tys = [bitcastPrim from to bitcastVec (LBitCast from to)
                       | from <- map ATInt vecTypes, to <- map ATInt vecTypes, from /= to]

mapHalf :: (V.Unbox a, V.Unbox b) => ((a, a) -> b) -> Vector a -> Vector b
mapHalf f xs = V.generate (V.length xs `div` 2) (\i -> f (xs V.! (i*2), xs V.! (i*2+1)))

mapDouble :: (V.Unbox a, V.Unbox b) => (Bool -> a -> b) -> Vector a -> Vector b
mapDouble f xs = V.generate (V.length xs * 2) (\i -> f (i `rem` 2 == 0) (xs V.! (i `div` 2)))

concatWord8 :: (Word8, Word8) -> Word16
concatWord8 (high, low) = fromIntegral high .|. (fromIntegral low `shiftL` 8)

concatWord16 :: (Word16, Word16) -> Word32
concatWord16 (high, low) = fromIntegral high .|. (fromIntegral low `shiftL` 16)

concatWord32 :: (Word32, Word32) -> Word64
concatWord32 (high, low) = fromIntegral high .|. (fromIntegral low `shiftL` 32)

truncWord16 :: Bool -> Word16 -> Word8
truncWord16 True x = fromIntegral (x `shiftR` 8)
truncWord16 False x = fromIntegral x

truncWord32 :: Bool -> Word32 -> Word16
truncWord32 True x = fromIntegral (x `shiftR` 16)
truncWord32 False x = fromIntegral x

truncWord64 :: Bool -> Word64 -> Word32
truncWord64 True x = fromIntegral (x `shiftR` 32)
truncWord64 False x = fromIntegral x

bitcastVec :: ArithTy -> [Const] -> Maybe Const
bitcastVec (ATInt (ITVec IT8  n)) [x@(B8V v)]
    | V.length v == n = Just x
bitcastVec (ATInt (ITVec IT16 n))   [B8V v]
    | V.length v == n*2 = Just . B16V . mapHalf concatWord8 $ v
bitcastVec (ATInt (ITVec IT32 n))   [B8V v]
    | V.length v == n*4 = Just . B32V . mapHalf concatWord16 . mapHalf concatWord8 $ v
bitcastVec (ATInt (ITVec IT64 n))   [B8V v]
    | V.length v == n*8 = Just . B64V . mapHalf concatWord32 . mapHalf concatWord16 . mapHalf concatWord8 $ v

bitcastVec (ATInt (ITVec IT8  n))   [B16V v]
    | V.length v * 2 == n = Just . B8V . mapDouble truncWord16 $ v
bitcastVec (ATInt (ITVec IT16 n)) [x@(B16V v)]
    | V.length v == n = Just x
bitcastVec (ATInt (ITVec IT32 n))   [B16V v]
    | V.length v == n*2 = Just . B32V . mapHalf concatWord16 $ v
bitcastVec (ATInt (ITVec IT64 n))   [B16V v]
    | V.length v == n*4 = Just . B64V . mapHalf concatWord32 . mapHalf concatWord16 $ v

bitcastVec (ATInt (ITVec IT8  n))   [B32V v]
    | V.length v * 4 == n = Just . B8V . mapDouble truncWord16 . mapDouble truncWord32 $ v
bitcastVec (ATInt (ITVec IT16 n))   [B32V v]
    | V.length v * 2 == n = Just . B16V . mapDouble truncWord32 $ v
bitcastVec (ATInt (ITVec IT32 n)) [x@(B32V v)]
    | V.length v == n = Just x
bitcastVec (ATInt (ITVec IT64 n))   [B32V v]
    | V.length v == n*2 = Just . B64V . mapHalf concatWord32 $ v

bitcastVec (ATInt (ITVec IT8  n))   [B64V v]
    | V.length v * 8 == n = Just . B8V . mapDouble truncWord16 . mapDouble truncWord32 . mapDouble truncWord64 $ v
bitcastVec (ATInt (ITVec IT16 n))   [B64V v]
    | V.length v * 4 == n = Just . B16V . mapDouble truncWord32 . mapDouble truncWord64 $ v
bitcastVec (ATInt (ITVec IT32 n))   [B64V v]
    | V.length v == n*2 = Just . B32V . mapDouble truncWord64 $ v
bitcastVec (ATInt (ITVec IT64 n)) [x@(B64V v)]
    | V.length v == n = Just x

bitcastVec _ _ = Nothing

mkVecCon :: NativeTy -> Int -> [Const] -> Maybe Const
mkVecCon ity count args
    | length ints == count = Just (mkVec ity count ints)
    | otherwise = Nothing
    where
      ints = getInt args
      mkVec :: NativeTy -> Int -> [Integer] -> Const
      mkVec IT8  len values = B8V  $ V.generate len (fromInteger . (values !!))
      mkVec IT16 len values = B16V $ V.generate len (fromInteger . (values !!))
      mkVec IT32 len values = B32V $ V.generate len (fromInteger . (values !!))
      mkVec IT64 len values = B64V $ V.generate len (fromInteger . (values !!))

mkVecIndex count [vec, B32 i] = Just (idxVec vec)
    where
      idxVec :: Const -> Const
      idxVec (B8V  v) = B8  $ V.unsafeIndex v (fromIntegral i)
      idxVec (B16V v) = B16 $ V.unsafeIndex v (fromIntegral i)
      idxVec (B32V v) = B32 $ V.unsafeIndex v (fromIntegral i)
      idxVec (B64V v) = B64 $ V.unsafeIndex v (fromIntegral i)
mkVecIndex _ _ = Nothing

mkVecUpdate ity count [vec, B32 i, newElem] = updateVec vec newElem
    where
      updateVec :: Const -> Const -> Maybe Const
      updateVec (B8V  v) (B8  e) = Just . B8V  $ V.unsafeUpdate v (V.singleton (fromIntegral i, e))
      updateVec (B16V v) (B16 e) = Just . B16V $ V.unsafeUpdate v (V.singleton (fromIntegral i, e))
      updateVec (B32V v) (B32 e) = Just . B32V $ V.unsafeUpdate v (V.singleton (fromIntegral i, e))
      updateVec (B64V v) (B64 e) = Just . B64V $ V.unsafeUpdate v (V.singleton (fromIntegral i, e))
      updateVec _ _ = Nothing
mkVecUpdate _ _ _ = Nothing

aTyName :: ArithTy -> String
aTyName (ATInt t) = intTyName t
aTyName ATFloat = "Float"

intTyName :: IntTy -> String
intTyName ITNative = "Int"
intTyName ITBig = "BigInt"
intTyName (ITFixed sized) = "B" ++ show (nativeTyWidth sized)
intTyName (ITChar) = "Char"
intTyName (ITVec ity count) = "B" ++ show (nativeTyWidth ity) ++ "x" ++ show count

iCmp  :: IntTy -> String -> Bool -> ([Const] -> Maybe Const) -> (IntTy -> PrimFn) -> Totality -> Prim
iCmp ity op self impl irop totality
    = Prim (UN $ "prim__" ++ op ++ intTyName ity)
      (ty (replicate 2 . AType . ATInt $ ity) (AType (ATInt (if self then ity else ITNative))))
      2 impl (2, irop ity) totality

iBinOp, iUnOp :: IntTy -> String -> ([Const] -> Maybe Const) -> (IntTy -> PrimFn) -> Totality -> Prim
iBinOp ity op impl irop totality
    = Prim (UN $ "prim__" ++ op ++ intTyName ity)
      (ty (replicate 2  . AType . ATInt $ ity) (AType . ATInt $ ity))
      2 impl (2, irop ity) totality
iUnOp ity op impl irop totality
    = Prim (UN $ "prim__" ++ op ++ intTyName ity)
      (ty [AType . ATInt $ ity] (AType . ATInt $ ity))
      1 impl (1, irop ity) totality

iCoerce :: IntTy -> IntTy -> String -> (IntTy -> IntTy -> [Const] -> Maybe Const) -> (IntTy -> IntTy -> PrimFn) -> Prim
iCoerce from to op impl irop =
    Prim (UN $ "prim__" ++ op ++ intTyName from ++ "_" ++ intTyName to)
             (ty [AType . ATInt $ from] (AType . ATInt $ to)) 1 (impl from to) (1, irop from to) total

fBin :: (Double -> Double -> Double) -> [Const] -> Maybe Const
fBin op [Fl x, Fl y] = Just $ Fl (op x y)
fBin _ _ = Nothing

bfBin :: (Double -> Double -> Bool) -> [Const] -> Maybe Const
bfBin op [Fl x, Fl y] = let i = (if op x y then 1 else 0) in
                        Just $ I i
bfBin _ _ = Nothing

bcBin :: (Char -> Char -> Bool) -> [Const] -> Maybe Const
bcBin op [Ch x, Ch y] = let i = (if op x y then 1 else 0) in
                        Just $ I i
bcBin _ _ = Nothing

bsBin :: (String -> String -> Bool) -> [Const] -> Maybe Const
bsBin op [Str x, Str y]
    = let i = (if op x y then 1 else 0) in
          Just $ I i
bsBin _ _ = Nothing

sBin :: (String -> String -> String) -> [Const] -> Maybe Const
sBin op [Str x, Str y] = Just $ Str (op x y)
sBin _ _ = Nothing

bsrem :: IntTy -> [Const] -> Maybe Const
bsrem ITBig [BI x, BI y] = Just . BI $ x `rem` y
bsrem (ITFixed IT8) [B8 x, B8 y]
    = Just $ B8 (fromIntegral (fromIntegral x `rem` fromIntegral y :: Int8))
bsrem (ITFixed IT16) [B16 x, B16 y]
    = Just $ B16 (fromIntegral (fromIntegral x `rem` fromIntegral y :: Int16))
bsrem (ITFixed IT32) [B32 x, B32 y]
    = Just $ B32 (fromIntegral (fromIntegral x `rem` fromIntegral y :: Int32))
bsrem (ITFixed IT64) [B64 x, B64 y]
    = Just $ B64 (fromIntegral (fromIntegral x `rem` fromIntegral y :: Int64))
bsrem ITNative [I x, I y] = Just $ I (x `rem` y)
bsrem ITChar [Ch x, Ch y] = Just $ Ch (chr $ (ord x) `rem` (ord y))
bsrem (ITVec IT8  _) [B8V  x, B8V  y]
    = Just . B8V  $
      V.zipWith (\n d -> (fromIntegral (fromIntegral n `rem` fromIntegral d :: Int8)))  x y
bsrem (ITVec IT16 _) [B16V x, B16V y]
    = Just . B16V $
      V.zipWith (\n d -> (fromIntegral (fromIntegral n `rem` fromIntegral d :: Int16))) x y
bsrem (ITVec IT32 _) [B32V x, B32V y]
    = Just . B32V $
      V.zipWith (\n d -> (fromIntegral (fromIntegral n `rem` fromIntegral d :: Int64))) x y
bsrem (ITVec IT64 _) [B64V x, B64V y]
    = Just . B64V $
      V.zipWith (\n d -> (fromIntegral (fromIntegral n `rem` fromIntegral d :: Int64))) x y
bsrem _ _ = Nothing

bsdiv :: IntTy -> [Const] -> Maybe Const
bsdiv ITBig [BI x, BI y] = Just . BI $ x `div` y
bsdiv (ITFixed IT8) [B8 x, B8 y]
    = Just $ B8 (fromIntegral (fromIntegral x `div` fromIntegral y :: Int8))
bsdiv (ITFixed IT16) [B16 x, B16 y]
    = Just $ B16 (fromIntegral (fromIntegral x `div` fromIntegral y :: Int16))
bsdiv (ITFixed IT32) [B32 x, B32 y]
    = Just $ B32 (fromIntegral (fromIntegral x `div` fromIntegral y :: Int32))
bsdiv (ITFixed IT64) [B64 x, B64 y]
    = Just $ B64 (fromIntegral (fromIntegral x `div` fromIntegral y :: Int64))
bsdiv ITNative [I x, I y] = Just $ I (x `div` y)
bsdiv ITChar [Ch x, Ch y] = Just $ Ch (chr $ (ord x) `div` (ord y))
bsdiv (ITVec IT8  _) [B8V  x, B8V  y]
    = Just . B8V  $
      V.zipWith (\n d -> (fromIntegral (fromIntegral n `div` fromIntegral d :: Int8)))  x y
bsdiv (ITVec IT16 _) [B16V x, B16V y]
    = Just . B16V $
      V.zipWith (\n d -> (fromIntegral (fromIntegral n `div` fromIntegral d :: Int16))) x y
bsdiv (ITVec IT32 _) [B32V x, B32V y]
    = Just . B32V $
      V.zipWith (\n d -> (fromIntegral (fromIntegral n `div` fromIntegral d :: Int64))) x y
bsdiv (ITVec IT64 _) [B64V x, B64V y]
    = Just . B64V $
      V.zipWith (\n d -> (fromIntegral (fromIntegral n `div` fromIntegral d :: Int64))) x y
bsdiv _ _ = Nothing

bashr :: IntTy -> [Const] -> Maybe Const
bashr ITBig [BI x, BI y] = Just $ BI (x `shiftR` fromIntegral y)
bashr (ITFixed IT8) [B8 x, B8 y]
    = Just $ B8 (fromIntegral (fromIntegral x `shiftR` fromIntegral y :: Int8))
bashr (ITFixed IT16) [B16 x, B16 y]
    = Just $ B16 (fromIntegral (fromIntegral x `shiftR` fromIntegral y :: Int16))
bashr (ITFixed IT32) [B32 x, B32 y]
    = Just $ B32 (fromIntegral (fromIntegral x `shiftR` fromIntegral y :: Int32))
bashr (ITFixed IT64) [B64 x, B64 y]
    = Just $ B64 (fromIntegral (fromIntegral x `shiftR` fromIntegral y :: Int64))
bashr ITNative [I x, I y] = Just $ I (x `shiftR` y)
bashr ITChar [Ch x, Ch y] = Just $ Ch (chr $ (ord x) `shiftR` (ord y))
bashr (ITVec IT8  _) [B8V  x, B8V  y]
    = Just . B8V  $
      V.zipWith (\n d -> (fromIntegral (fromIntegral n `shiftR` fromIntegral d :: Int8)))  x y
bashr (ITVec IT16 _) [B16V x, B16V y]
    = Just . B16V $
      V.zipWith (\n d -> (fromIntegral (fromIntegral n `shiftR` fromIntegral d :: Int16))) x y
bashr (ITVec IT32 _) [B32V x, B32V y]
    = Just . B32V $
      V.zipWith (\n d -> (fromIntegral (fromIntegral n `shiftR` fromIntegral d :: Int64))) x y
bashr (ITVec IT64 _) [B64V x, B64V y]
    = Just . B64V $
      V.zipWith (\n d -> (fromIntegral (fromIntegral n `shiftR` fromIntegral d :: Int64))) x y
bashr _ _ = Nothing

bUn :: IntTy -> (forall a. Bits a => a -> a) -> [Const] -> Maybe Const
bUn (ITFixed IT8)      op [B8  x] = Just $ B8  (op x)
bUn (ITFixed IT16)     op [B16 x] = Just $ B16 (op x)
bUn (ITFixed IT32)     op [B32 x] = Just $ B32 (op x)
bUn (ITFixed IT64)     op [B64 x] = Just $ B64 (op x)
bUn ITBig    op [BI x]  = Just $ BI (op x)
bUn ITNative op [I x]   = Just $ I (op x)
bUn ITChar op [Ch x] = Just $ Ch (chr $ op (ord x))
bUn (ITVec IT8  _) op [B8V  x] = Just . B8V  $ V.map op x
bUn (ITVec IT16 _) op [B16V x] = Just . B16V $ V.map op x
bUn (ITVec IT32 _) op [B32V x] = Just . B32V $ V.map op x
bUn (ITVec IT64 _) op [B64V x] = Just . B64V $ V.map op x
bUn _        _   _      = Nothing

bitBin :: IntTy -> (forall a. (Bits a, Integral a) => a -> a -> a) -> [Const] -> Maybe Const
bitBin (ITFixed IT8)      op [B8  x, B8  y] = Just $ B8  (op x y)
bitBin (ITFixed IT16)     op [B16 x, B16 y] = Just $ B16 (op x y)
bitBin (ITFixed IT32)     op [B32 x, B32 y] = Just $ B32 (op x y)
bitBin (ITFixed IT64)     op [B64 x, B64 y] = Just $ B64 (op x y)
bitBin ITBig    op [BI x,  BI y]  = Just $ BI (op x y)
bitBin ITNative op [I x,   I y]   = Just $ I (op x y)
bitBin ITChar   op [Ch x,  Ch y]   = Just $ Ch (chr $ op (ord x) (ord y))
bitBin (ITVec IT8  _) op [B8V  x, B8V  y] = Just . B8V  $ V.zipWith op x y
bitBin (ITVec IT16 _) op [B16V x, B16V y] = Just . B16V $ V.zipWith op x y
bitBin (ITVec IT32 _) op [B32V x, B32V y] = Just . B32V $ V.zipWith op x y
bitBin (ITVec IT64 _) op [B64V x, B64V y] = Just . B64V $ V.zipWith op x y
bitBin _        _  _              = Nothing

bCmp :: IntTy -> (forall a. (Integral a, Ord a) => a -> a -> Bool) -> [Const] -> Maybe Const
bCmp (ITFixed IT8)      op [B8  x, B8  y] = Just $ I (if (op x y) then 1 else 0)
bCmp (ITFixed IT16)     op [B16 x, B16 y] = Just $ I (if (op x y) then 1 else 0)
bCmp (ITFixed IT32)     op [B32 x, B32 y] = Just $ I (if (op x y) then 1 else 0)
bCmp (ITFixed IT64)     op [B64 x, B64 y] = Just $ I (if (op x y) then 1 else 0)
bCmp ITBig    op [BI x, BI y]   = Just $ I (if (op x y) then 1 else 0)
bCmp ITNative op [I x, I y]     = Just $ I (if (op x y) then 1 else 0)
bCmp ITChar   op [Ch x, Ch y]     = Just $ I (if (op (ord x) (ord y)) then 1 else 0)
bCmp (ITVec IT8 _)  op [B8V  x, B8V  y]
    = Just . B8V . V.map (\b -> if b then -1 else 0) $ V.zipWith op x y
bCmp (ITVec IT16 _) op [B16V x, B16V y]
    = Just . B16V . V.map (\b -> if b then -1 else 0) $ V.zipWith op x y
bCmp (ITVec IT32 _) op [B32V x, B32V y]
    = Just . B32V . V.map (\b -> if b then -1 else 0) $ V.zipWith op x y
bCmp (ITVec IT64 _) op [B64V x, B64V y]
    = Just . B64V . V.map (\b -> if b then -1 else 0) $ V.zipWith op x y
bCmp _        _  _              = Nothing


cmpOp :: (Ord a, Integral a) => IntTy -> (forall b. Ord b => b -> b -> Bool) -> a -> a -> Bool
cmpOp (ITFixed _) f = f
cmpOp (ITNative)  f = f `on` (fromIntegral :: Integral a => a -> Word)
cmpOp (ITChar)    f = f `on` ((fromIntegral :: Integral a => a -> Word))
cmpOp _ f = let xor = (/=) in (\ x y -> (f x y) `xor` (x < 0) `xor` (y < 0))

sCmpOp :: (Ord a, Integral a) => IntTy -> (forall b. Ord b => b -> b -> Bool) -> a -> a -> Bool
sCmpOp (ITFixed IT8) f = f `on` (fromIntegral :: Integral a => a -> Int8)
sCmpOp (ITFixed IT16) f = f `on` (fromIntegral :: Integral a => a -> Int16)
sCmpOp (ITFixed IT32) f = f `on` (fromIntegral :: Integral a => a -> Int32)
sCmpOp (ITFixed IT64) f = f `on` (fromIntegral :: Integral a => a -> Int64)
sCmpOp _ f = f

toInt :: Integral a => IntTy -> a -> Const
toInt (ITFixed IT8)      x = B8 (fromIntegral x)
toInt (ITFixed IT16)     x = B16 (fromIntegral x)
toInt (ITFixed IT32)     x = B32 (fromIntegral x)
toInt (ITFixed IT64)     x = B64 (fromIntegral x)
toInt ITBig    x = BI (fromIntegral x)
toInt ITNative x = I (fromIntegral x)
toInt ITChar x = Ch (chr $ fromIntegral x)

intToInt :: IntTy -> IntTy -> [Const] -> Maybe Const
intToInt (ITFixed IT8)      out [B8  x] = Just $ toInt out x
intToInt (ITFixed IT16)     out [B16 x] = Just $ toInt out x
intToInt (ITFixed IT32)     out [B32 x] = Just $ toInt out x
intToInt (ITFixed IT64)     out [B64 x] = Just $ toInt out x
intToInt ITBig              out [BI  x] = Just $ toInt out x
intToInt ITNative           out [I   x] = Just $ toInt out x
intToInt ITChar             out [Ch  x] = Just $ toInt out (ord x)
intToInt _ _ _ = Nothing

zext :: IntTy -> IntTy -> [Const] -> Maybe Const
zext from ITBig val = intToInt from ITBig val
zext ITBig _ _ = Nothing
zext f@(ITFixed from) t@(ITFixed to) val
    | nativeTyWidth from < nativeTyWidth to = intToInt f t val
zext ITNative to [I x] = Just $ toInt to (fromIntegral x :: Word)
zext from ITNative val = intToInt from ITNative val
zext _ _ _ = Nothing

sext :: IntTy -> IntTy -> [Const] -> Maybe Const
sext (ITFixed IT8)  out [B8  x] = Just $ toInt out (fromIntegral x :: Int8)
sext (ITFixed IT16) out [B16 x] = Just $ toInt out (fromIntegral x :: Int16)
sext (ITFixed IT32) out [B32 x] = Just $ toInt out (fromIntegral x :: Int32)
sext (ITFixed IT64) out [B64 x] = Just $ toInt out (fromIntegral x :: Int64)
sext ITBig _  _       = Nothing
sext from to  val     = intToInt from to val

trunc :: IntTy -> IntTy -> [Const] -> Maybe Const
trunc ITBig to val = intToInt ITBig to val
trunc _ ITBig _ = Nothing
trunc f@(ITFixed from) t@(ITFixed to) val | nativeTyWidth from > nativeTyWidth to = intToInt f t val
trunc ITNative to [I x] = Just $ toInt to x
trunc from ITNative val = intToInt from ITNative val
trunc _ _ _ = Nothing

intToStr :: [Const] -> Maybe Const
intToStr val | [i] <- getInt val = Just $ Str (show i)
intToStr _ = Nothing

getInt :: [Const] -> [Integer]
getInt (B8 x : xs) = toInteger x : getInt xs
getInt (B16 x : xs) = toInteger x : getInt xs
getInt (B32 x : xs) = toInteger x : getInt xs
getInt (B64 x : xs) = toInteger x : getInt xs
getInt (I x : xs) = toInteger x : getInt xs
getInt (BI x : xs) = x : getInt xs
getInt _ = []

strToInt :: IntTy -> [Const] -> Maybe Const
strToInt ity [Str x] = case reads x of
                         [(n,"")] -> Just $ toInt ity (n :: Integer)
                         _        -> Just $ I 0
strToInt _ _ = Nothing

intToFloat :: [Const] -> Maybe Const
intToFloat val | [i] <- getInt val = Just $ Fl (fromIntegral i)
intToFloat _ = Nothing

floatToInt :: IntTy -> [Const] -> Maybe Const
floatToInt ity [Fl x] = Just $ toInt ity (truncate x :: Integer)
floatToInt _ _ = Nothing

c_intToChar, c_charToInt :: [Const] -> Maybe Const
c_intToChar [(I x)] = Just . Ch . toEnum $ x
c_intToChar _ = Nothing
c_charToInt [(Ch x)] = Just . I . fromEnum $ x
c_charToInt _ = Nothing

c_floatToStr :: [Const] -> Maybe Const
c_floatToStr [Fl x] = Just $ Str (show x)
c_floatToStr _ = Nothing
c_strToFloat [Str x] = case reads x of
                         [(n,"")] -> Just $ Fl n
                         _ -> Just $ Fl 0
c_strToFloat _ = Nothing

p_fPrim :: (Double -> Double) -> [Const] -> Maybe Const
p_fPrim f [Fl x] = Just $ Fl (f x)
p_fPrim f _ = Nothing

p_floatExp, p_floatLog, p_floatSin, p_floatCos, p_floatTan, p_floatASin, p_floatACos, p_floatATan, p_floatSqrt, p_floatFloor, p_floatCeil :: [Const] -> Maybe Const
p_floatExp = p_fPrim exp
p_floatLog = p_fPrim log
p_floatSin = p_fPrim sin
p_floatCos = p_fPrim cos
p_floatTan = p_fPrim tan
p_floatASin = p_fPrim asin
p_floatACos = p_fPrim acos
p_floatATan = p_fPrim atan
p_floatSqrt = p_fPrim sqrt
p_floatFloor = p_fPrim (fromInteger . floor)
p_floatCeil = p_fPrim (fromInteger . ceiling)

p_strLen, p_strHead, p_strTail, p_strIndex, p_strCons, p_strRev :: [Const] -> Maybe Const
p_strLen [Str xs] = Just $ I (length xs)
p_strLen _ = Nothing
p_strHead [Str (x:xs)] = Just $ Ch x
p_strHead _ = Nothing
p_strTail [Str (x:xs)] = Just $ Str xs
p_strTail _ = Nothing
p_strIndex [Str xs, I i]
   | i < length xs = Just $ Ch (xs!!i)
p_strIndex _ = Nothing
p_strCons [Ch x, Str xs] = Just $ Str (x:xs)
p_strCons _ = Nothing
p_strRev [Str xs] = Just $ Str (reverse xs)
p_strRev _ = Nothing

p_cantreduce :: a -> Maybe b
p_cantreduce _ = Nothing


