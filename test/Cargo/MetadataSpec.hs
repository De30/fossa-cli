module Cargo.MetadataSpec (
  spec,
) where

import Data.Aeson
import Data.ByteString.Lazy qualified as BL
import Data.Map.Strict qualified as Map
import Data.Set qualified as Set
import Data.Text (Text)
import Data.Text qualified as Text
import DepTypes
import GraphUtil
import Graphing
import Strategy.Cargo
import Test.Hspec qualified as Test

expectedMetadata :: CargoMetadata
expectedMetadata = CargoMetadata [] [jfmtId] $ Resolve expectedResolveNodes

expectedResolveNodes :: [ResolveNode]
expectedResolveNodes = [ansiTermNode, clapNode, jfmtNode]

registrySource :: Text.Text
registrySource = "(registry+https://github.com/rust-lang/crates.io-index)"

mkPkgId :: Text.Text -> Text.Text -> PackageId
mkPkgId name ver = PackageId name ver registrySource

mkDep :: Text -> Text -> [DepEnvironment] -> Dependency
mkDep name version envs = Dependency CargoType name (Just $ CEq version) [] (Set.fromList envs) Map.empty

ansiTermId :: PackageId
ansiTermId = mkPkgId "ansi_term" "0.11.0"

ansiTermDep :: Dependency
ansiTermDep = mkDep "ansi_term" "0.11.0" [EnvProduction]

clapId :: PackageId
clapId = mkPkgId "clap" "2.33.0"

clapDep :: Dependency
clapDep = mkDep "clap" "2.33.0" [EnvProduction]

jfmtId :: PackageId
jfmtId = PackageId "jfmt" "1.0.0" "(path+file:///path/to/jfmt.rs)"

ansiTermNode :: ResolveNode
ansiTermNode = ResolveNode ansiTermId []

clapNode :: ResolveNode
clapNode = ResolveNode clapId [NodeDependency ansiTermId [NodeDepKind Nothing $ Just "cfg(not(windows))"]]

jfmtNode :: ResolveNode
jfmtNode = ResolveNode jfmtId [NodeDependency clapId [nullKind]]

nullKind :: NodeDepKind
nullKind = NodeDepKind Nothing Nothing

spec :: Test.Spec
spec = do
  Test.describe "cargo metadata parser" $ do
    metaBytes <- Test.runIO $ BL.readFile "test/Cargo/testdata/expected-metadata.json"
    Test.it "should properly construct a resolution tree" $
      case eitherDecode metaBytes of
        Left err -> Test.expectationFailure $ "failed to parse: " ++ err
        Right result -> result `Test.shouldBe` expectedMetadata

  Test.describe "cargo metadata graph" $ do
    let graph = pruneUnreachable $ buildGraph expectedMetadata

    Test.it "should build the correct graph" $ do
      expectDeps [ansiTermDep, clapDep] graph
      expectEdges [(clapDep, ansiTermDep)] graph
      expectDirect [clapDep] graph
