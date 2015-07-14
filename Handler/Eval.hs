{-# language StandaloneDeriving #-}
{-# language FlexibleInstances #-}
module Handler.Eval where

import Import
import Data.Map (Map)
import qualified Data.Map as Map
import Presenter.StarExec.JobData
import Presenter.Internal.Stringish()
import Presenter.Processing
import Presenter.Statistics
import Presenter.Utils.WidgetMetaRefresh
import Presenter.Utils.WidgetTable
import Text.Lucius (luciusFile)
import Data.Double.Conversion.Text
import Data.Maybe
import qualified Data.Map.Strict as M
import qualified Data.List as L
import qualified Data.Text as T

toTuples :: (a, [b]) -> [(a,b)]
toTuples (i, solvers) = map ((,) i) solvers

shorten :: Text -> Text
shorten t = if T.length t > 50
              then shorten $ T.tail t
              else t

-- copied from: http://rosettacode.org/wiki/Power_set#Haskell
powerset = foldr (\x acc -> acc ++ map (x:) acc) [[]]

-- projection :: [a] -> (a->a) -> [a]
-- projection k = 


-- multiple predicates for one function to check relation between object and attribute

-- getFunc :: String -> (a->b)
--getFunc funcName
--  | funcName == "even" = even
--  | funcName == "odd"  = odd


-- constructConcepts :: [a] -> Map k v

-- constructConcepts :: [a] -> ([a])
-- constructConcepts numbers = do
--  let evenNumbers = [n | n <- numbers, all even n]
--  let oddNumbers = [n | n <- numbers, all odd n]
  -- return [("even", evenNumbers), ("odd", oddNumbers)]
  --(evenNumbers, oddNumbers)


--copied from ShowManyJobResults.hs

getEvalR :: Query -> JobIds -> Handler Html
getEvalR NoQuery  jids@(JobIds ids) = do
  qJobs <- queryManyJobs ids
  let jobInfos = catMaybes $ map (fst . queryResult) qJobs
      complexity = all isComplexity jobInfos
      jobs = map (snd . queryResult) qJobs

      jobResults :: [JobResult]
      jobResults = concat $ jobs

      conceptPairs :: [(Text, Text)]
      conceptPairs = [("o1","a1"),("o2","a2"),("o3","a3")]

      benchmarks' = L.sortBy compareBenchmarks $
                      getInfo extractBenchmark $ jobResults
      groupedSolvers = map (getInfo extractSolver) jobs
      jobSolvers = concat $ map toTuples $ zip ids groupedSolvers
      benchmarkResults = getBenchmarkResults
                          jobSolvers
                          jobResults
                          benchmarks'
      scores = flip map jobs $
        \results ->
          if complexity
            then calcComplexityScores results
            else calcStandardScores results
  defaultLayout $ do
    toWidget $(luciusFile "templates/solver_result.lucius")
    if any (\q -> queryStatus q /= Latest) qJobs
      then insertWidgetMetaRefresh
      else return ()
    $(widgetFile "eval")


getEvalR q@(Query ts) jids @ (JobIds ids) = do
  qJobs <- queryManyJobs ids
  tab <- getManyJobCells $ map (snd . queryResult) qJobs
  defaultLayout $ do
    setTitle "FCA"
    toWidget $(luciusFile "templates/solver_result.lucius")
    if any (\q' -> queryStatus q' /= Latest) qJobs
      then insertWidgetMetaRefresh
      else return ()
    [whamlet|
            <pre>#{show q}
        |]
    display jids [] ts tab


-- alias lookup function to has a FCA context wording
-- get an attribute to a given object
getAttribute :: (Eq a) => a -> [(a,b)] -> Maybe b
getAttribute a b = lookup a b


-- http://hackage.haskell.org/package/base-4.8.0.0/docs/src/GHC-List.html#lookup
-- implementation of lookup to get an object to a given attribute
getObject              :: (Eq b) => b -> [(a,b)] -> Maybe a
getObject _key []          =  Nothing
getObject  key ((x,y):xys)
    | key == y          =  Just x
    | otherwise         =  getObject key xys
