module Handler.Import where

import Import

import Yesod.Auth
import Yesod.Form.Bootstrap3

import Presenter.Internal.Stringish

data SourceSelection = LRISelection | UIBKSelection
  deriving (Eq, Ord, Read, Show)

data UploadContent = UploadContent
  { source :: SourceSelection
  , file :: FileInfo
  }

uploadForm :: Form UploadContent
uploadForm = renderBootstrap3 BootstrapBasicForm $ UploadContent
  <$> areq (selectFieldList [("LRI"::Text, LRISelection), ("UIBK"::Text, UIBKSelection)]) "Source:" Nothing
  <*> fileAFormReq "Archive:"

getImportR :: Handler Html
getImportR = do
  maid <- maybeAuthId
  ((_, widget), enctype) <- runFormPost uploadForm
  let mUploadContent = Nothing :: Maybe UploadContent
      mFormError = Nothing :: Maybe Text
  defaultLayout $(widgetFile "import")


postImportR :: Handler Html
postImportR = do
  maid <- maybeAuthId
  ((result, widget), enctype) <- runFormPost uploadForm
  let mUploadContent = case result of
        FormSuccess r -> Just r
        _ -> Nothing
      mFormError = case result of
        FormSuccess _ -> Nothing
        FormMissing -> Just ("FormMissing" :: Text)
        FormFailure ts -> Just (mconcat ts)
  defaultLayout $(widgetFile "import")
