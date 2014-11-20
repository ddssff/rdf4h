module W3C.TurtleTest where

import Test.Framework.Providers.API
import Test.Framework.Providers.HUnit
import qualified Test.HUnit as TU
import qualified Data.Text as T

import W3C.Manifest

import Data.RDF.Types
import Data.RDF.Query
import Text.RDF.RDF4H.TurtleParser
import Data.RDF.TriplesGraph

suiteFilesDir = "data/w3c/turtle/"

mfPath = T.concat [suiteFilesDir, "manifest.ttl"]
mfBaseURI = "http://www.w3.org/2013/TurtleTests/"

tests :: [Test]
tests = [ buildTest allTurtleTests ]

allTurtleTests :: IO Test
allTurtleTests = do
  m <- loadManifest mfPath mfBaseURI
  return $ testGroup "W3C Turtle Tests" $ map (buildTest . mfEntryToTest) $ entries m

-- Functions to map manifest test entries to unit tests.
-- They are defined here to avoid cluttering W3C.Manifest
-- with functions that may not be needed to those who
-- just want to parse Manifest files.
-- TODO: They should probably be moved to W3C.Manifest after all.
mfEntryToTest :: TestEntry -> IO Test
mfEntryToTest (TestTurtleEval nm cmt apr act res) = do
  parsedRDF <- parseFile parserA (nodeURI act) >>= return . fromEither :: IO TriplesGraph
  expectedRDF <- parseFile parserB (nodeURI res) >>= return . fromEither :: IO TriplesGraph
  return $ testCase (T.unpack nm) $ TU.assert $ isIsomorphic parsedRDF expectedRDF
  where parserA = TurtleParser (Just (BaseUrl mfBaseURI)) (Just mfBaseURI)
        parserB = TurtleParser (Just (BaseUrl mfBaseURI)) (Just mfBaseURI)
        nodeURI = \(UNode u) -> T.unpack $ T.concat [suiteFilesDir, last $ T.split (\c -> c == '/') u]
mfEntryToTest (TestTurtleNegativeEval nm cmt apr act) = do
  rdf <- parseFile parser (nodeURI act) :: IO (Either ParseFailure TriplesGraph)
  return $ testCase (T.unpack nm) $ TU.assert $ isNotParsed rdf
  where parser = TurtleParser (Just (BaseUrl mfBaseURI)) (Just mfBaseURI)
        nodeURI = \(UNode u) -> T.unpack $ T.concat [suiteFilesDir, last $ T.split (\c -> c == '/') u]
mfEntryToTest (TestTurtlePositiveSyntax nm cmt apr act) = do
  rdf <- parseFile parser (nodeURI act) :: IO (Either ParseFailure TriplesGraph)
  return $ testCase (T.unpack nm) $ TU.assert $ isParsed rdf
  where parser = TurtleParser (Just (BaseUrl mfBaseURI)) (Just mfBaseURI)
        nodeURI = \(UNode u) -> T.unpack $ T.concat [suiteFilesDir, last $ T.split (\c -> c == '/') u]
mfEntryToTest (TestTurtleNegativeSyntax nm cmt apr act) = do
  rdf <- parseFile parser (nodeURI act) :: IO (Either ParseFailure TriplesGraph)
  return $ testCase (T.unpack nm) $ TU.assert $ isNotParsed rdf
  where parser = TurtleParser (Just (BaseUrl mfBaseURI)) (Just mfBaseURI)
        nodeURI = \(UNode u) -> T.unpack $ T.concat [suiteFilesDir, last $ T.split (\c -> c == '/') u]

isParsed :: Either a b -> Bool
isParsed (Left _) = False
isParsed (Right _) = True

isNotParsed :: Either a b -> Bool
isNotParsed = not . isParsed