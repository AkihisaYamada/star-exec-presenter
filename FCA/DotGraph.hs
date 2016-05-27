module FCA.DotGraph where

import FCA.StarExec as FSE
import FCA.Basic
import Import hiding (delete)
import Presenter.Utils.Colors as C

import Control.Monad
import Data.Graph.Inductive hiding (getNodes)
import Data.GraphViz as G
import Data.GraphViz.Algorithms
import Data.GraphViz.Attributes.Complete as GA
import Data.GraphViz.Attributes.HTML as GAH
import Data.GraphViz.Printing
import Data.List as L
import Data.Maybe
import Data.Set as S
import Data.Text as T hiding (length, map)
import qualified Data.Text.Lazy as TL


dottedGraph :: (Eq ob, Show ob) => [Concept ob FSE.Attribute] -> [T.Text] -> String
dottedGraph conceptLattice nodeURLs = do
  let graph_params = getGraphParams conceptLattice nodeURLs
  let graphWithTransEdges = G.graphToDot graph_params $ createGraph conceptLattice
  (TL.unpack . renderDot) . toDot $ transitiveReduction graphWithTransEdges

createGraph :: (Eq ob, Eq at, Show at, Ord at) => [Concept ob at] -> (Gr TL.Text TL.Text)
createGraph conceptLattice = mkGraph (getNodes conceptLattice) $ getEdges conceptLattice

getNodes :: (Eq ob, Eq at, Show at) => [Concept ob at] -> [LNode TL.Text]
getNodes conceptLattice = L.map
 (\c -> (fromJust $ elemIndex c conceptLattice, " ")) conceptLattice

getEdges :: (Eq ob, Eq at, Ord at) => [Concept ob at] -> [LEdge TL.Text]
getEdges conceptLattice = do
  concept <- conceptLattice
  concept2 <- conceptLattice
  guard (isProperSubsetOf (ats concept) (ats concept2))
  -- math: ats concept < ats concept2 --> Edge((ats concept), (ats concept2))
  return (fromJust $ elemIndex concept conceptLattice, fromJust $ elemIndex concept2 conceptLattice, " ")

getGraphParams :: (Integral n, Show n) => [Concept ob FSE.Attribute] -> [T.Text] -> G.GraphvizParams n TL.Text TL.Text () TL.Text
getGraphParams conceptLattice nodeURLs = G.nonClusteredParams {
  G.globalAttributes = [G.GraphAttrs [GA.RankDir GA.FromTop
                                     , GA.Size GA.GSize {width=15, height=Nothing, desiredSize=False}
                                     , GA.Tooltip " "
                                     ]]
  , G.isDirected       = True
  , G.fmtNode          = \ (n, _) -> do
    let concept = conceptLattice!!(fromIntegral n)
    let (atLabels,nodeColor) = replaceLabelWithColor . S.map properAttrName $ ats concept
    -- https://hackage.haskell.org/package/graphviz-2999.18.0.2/docs/Data-GraphViz-Attributes-HTML.html#t:Table
    [GA.Shape GA.PlainText, GA.Label $ GA.HtmlLabel $ GAH.Table $ GAH.HTable Nothing
      [GAH.CellBorder 0, GAH.BGColor nodeColor, HRef $ TL.fromStrict $ nodeURLs!!(fromIntegral n), Title " "]
        [ -- first row:
          GAH.Cells [GAH.LabelCell [Align HCenter, Title " "] $ GAH.Text [GAH.Format GAH.Underline $ [GAH.Str $ TL.pack $ (++) (show $ length $ obs concept) " job-pair(s)."]]],
          -- second row:
          GAH.Cells [GAH.LabelCell [Title " "] $ GAH.Text $ L.intersperse (GAH.Newline []) $
            L.map (\label -> GAH.Str $ TL.fromStrict $ stripAttributePrefixes label) $ toList atLabels]
        ]]
}

getSolverResultColor :: T.Text -> Color
getSolverResultColor solverResults
    | containsYes solverResults = C.colorYes
    | containsNo solverResults = C.colorNo
    | containsMaybe solverResults  = C.colorMaybe
    | containsBounds solverResults  = C.colorBounds
    | containsCertified solverResults  = C.colorCertified
    | containsError solverResults  = C.colorError
    | otherwise = C.colorAnything
    where
      containsYes = T.isInfixOf "YES"
      containsNo = T.isInfixOf "NO"
      containsMaybe = T.isInfixOf "MAYBE"
      containsBounds = T.isInfixOf "BOUNDS"
      containsCertified = T.isInfixOf "CERTIFIED"
      containsError = T.isInfixOf "ERROR"

replaceLabelWithColor :: Set T.Text -> (Set T.Text, Color)
replaceLabelWithColor labels = do
  let solverResults = S.filter (\at -> "Result " `T.isPrefixOf` at) labels
  if length solverResults == 1
    then
      (difference labels solverResults, getSolverResultColor $ S.elemAt 0 solverResults)
    else (difference labels solverResults, toColor G.White)
