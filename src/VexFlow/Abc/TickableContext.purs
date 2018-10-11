module VexFlow.Abc.TickableContext where

-- | A 'tickable' item is a first class item that exists on a bar stave
-- | and occupies real estate - notably notes and rests.
-- | We need to take account of these in each bar ( for instance, to determine
-- | the start position amongst the tickables of any tuplet)

import Prelude (class Semigroup, class Monoid, (+), (*), mempty)
import Data.Abc (Music(..), NoteDuration, RestOrNote)
import Data.Rational ((%), fromInt)
import Data.Either (Either(..))
import Data.Foldable (foldl)
import Data.List.NonEmpty (head, toUnfoldable) as Nel

type NoteCount = Int

data  TickableContext = TickableContext NoteCount NoteDuration

instance tickableSemigroupCtx :: Semigroup TickableContext where
  append (TickableContext c1 d1) (TickableContext c2 d2) =
    TickableContext (c1 + c2) (d1 + d2)

instance tickableMonoidCtx :: Monoid TickableContext where
  mempty = TickableContext 0 (fromInt 0)

-- | get the tickable content of any Music item
getTickableContext :: Music -> TickableContext
getTickableContext m =
  case m of
    Note abcNote ->
      TickableContext 1 abcNote.duration

    Rest { duration } ->
      TickableContext 1 duration

    Chord abcChord ->
      let
        abcNote = Nel.head abcChord.notes
        duration = abcChord.duration * abcNote.duration
      in
        TickableContext 1 duration

    BrokenRhythmPair abcNote1 broken abcNote2 ->
      TickableContext 1 (abcNote1.duration + abcNote2.duration)

    Tuplet signature rOrNs ->
      let
        reduction = signature.q % signature.p
        duration = reduction * (getRorNsDuration (Nel.toUnfoldable rOrNs))
      in
        TickableContext signature.r duration

    _ ->
      mempty


getRorNsDuration :: Array RestOrNote -> NoteDuration
getRorNsDuration rOrNs =
  let
    f acc rOrN =
      case rOrN of
        Left rest -> rest.duration + acc
        Right note -> note.duration + acc
  in
    foldl f (fromInt 0) rOrNs