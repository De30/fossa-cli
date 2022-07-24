{-# LANGUAGE BangPatterns #-}

module Container.Errors (ContainerImgParsingError (..)) where

import Codec.Archive.Tar qualified as Tar
import Control.DeepSeq (NFData (rnf))
import Control.Effect.Diagnostics (ToDiagnostic (renderDiagnostic))
import Control.Exception (Exception)
import Effect.Logger (pretty)

-- | Errors that can be encountered when parsing a container image.
data ContainerImgParsingError
  = ManifestFileMissing
  | ManifestJsonNotFound
  | ManifestJsonParsingFailed String
  | TarParserError Tar.FormatError
  | TarMissingLayerTar FilePath
  deriving (Eq)

instance Show ContainerImgParsingError where
  show ManifestFileMissing = "ManifestFileMissing - could not find manifest.json in tarball."
  show ManifestJsonNotFound = "ManifestJsonNotFound - could not find manifest.json in tarball."
  show (ManifestJsonParsingFailed err) = "ManifestJsonParsingFailed: " <> show err
  show (TarParserError err) = "TarParserError: " <> show err
  show (TarMissingLayerTar path) = "TarMissingLayerTar: " <> show path

instance Exception ContainerImgParsingError

instance NFData ContainerImgParsingError where
  rnf !_ = () -- fully strict by construction

instance ToDiagnostic ContainerImgParsingError where
  renderDiagnostic = pretty . show
