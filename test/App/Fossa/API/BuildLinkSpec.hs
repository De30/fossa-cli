{-# LANGUAGE GADTs #-}
{-# LANGUAGE QuasiQuotes #-}

module App.Fossa.API.BuildLinkSpec (spec) where

import App.Fossa.API.BuildLink (getBuildURLWithOrg, getFossaBuildUrl)
import App.Types (ProjectRevision (ProjectRevision))
import Control.Effect.FossaApiClient (
  FossaApiClientF (GetApiOpts, GetOrganization),
 )
import Data.Text (Text)
import Fossa.API.Types (
  ApiKey (ApiKey),
  ApiOpts (ApiOpts),
  Organization (Organization),
 )
import Srclib.Types (Locator (Locator))
import Test.Effect (it', shouldBe', withMockApi)
import Test.Hspec (Spec, describe)
import Text.URI.QQ (uri)

simpleSamlPath :: Text
simpleSamlPath = "https://app.fossa.com/account/saml/1?next=/projects/fetcher123%252bproject123/refs/branch/master123/revision123"

-- All reserved characters in the 'next' URI get encoded once during render of
-- the query value. Then the resulting '%' symbols are themselves
-- percent-encoded during final rendering of the URI.  For example, the process
-- for '@' works this way: '@' -> '%40' -> '%2540'
gitSamlPath :: Text
gitSamlPath = "https://app.fossa.com/account/saml/103?next=/projects/fetcher%2540123%252fabc%252bgit%2540github.com%252fuser%252frepo/refs/branch/weird--branch/revision%2540123%252fabc"

fullSamlURL :: Text
fullSamlURL = "https://app.fossa.com/account/saml/33?next=/projects/a%252bb/refs/branch/master/c"

simpleStandardURL :: Text
simpleStandardURL = "https://app.fossa.com/projects/haskell%2b89%2fspectrometer/refs/branch/master/revision123"

spec :: Spec
spec = do
  describe "BuildLink" $ do
    let apiOpts = ApiOpts (Just [uri|https://app.fossa.com/|]) $ ApiKey ""
    describe "SAML URL builder" $ do
      it' "should render simple locators" $ do
        let locator = Locator "fetcher123" "project123" $ Just "revision123"
            org = Just $ Organization 1 True False
            revision = ProjectRevision "" "not this revision" $ Just "master123"
        -- Loggers and Diagnostics modify monads, so we need a no-op monad
        actual <- getBuildURLWithOrg org revision apiOpts locator

        actual `shouldBe'` simpleSamlPath

      it' "should render git@ locators" $ do
        let locator = Locator "fetcher@123/abc" "git@github.com/user/repo" $ Just "revision@123/abc"
            org = Just $ Organization 103 True False
            revision = ProjectRevision "not this project name" "not this revision" $ Just "weird--branch"
        actual <- getBuildURLWithOrg org revision apiOpts locator

        actual `shouldBe'` gitSamlPath

      it' "should render full url correctly" $ do
        let locator = Locator "a" "b" $ Just "c"
            org = Just $ Organization 33 True False
            revision = ProjectRevision "" "not this revision" $ Just "master"
        actual <- getBuildURLWithOrg org revision apiOpts locator

        actual `shouldBe'` fullSamlURL

    describe "Standard URL Builder" $ do
      it' "should render simple links" $ do
        let locator = Locator "haskell" "89/spectrometer" $ Just "revision123"
            revision = ProjectRevision "" "not this revision" $ Just "master"
        actual <- getBuildURLWithOrg Nothing revision apiOpts locator

        actual `shouldBe'` simpleStandardURL

    describe "Fossa URL Builder" $
      it' "should render from API info"
        . withMockApi
          ( \case
              GetApiOpts -> pure apiOpts
              GetOrganization -> pure $ Organization 1 True False
          )
        $ do
          let locator = Locator "fetcher123" "project123" $ Just "revision123"
              revision = ProjectRevision "" "not this revision" $ Just "master123"
          actual <- getFossaBuildUrl revision locator

          actual `shouldBe'` simpleSamlPath