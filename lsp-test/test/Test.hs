{-# LANGUAGE DuplicateRecordFields #-}
{-# LANGUAGE OverloadedStrings #-}
import           Test.Hspec
import           Data.Maybe
import           Data.Proxy
import           Control.Monad.IO.Class
import           Control.Lens hiding (List)
import           Language.Haskell.LSP.Test
import           Language.Haskell.LSP.Test.Replay
import           Language.Haskell.LSP.Types
import           Language.Haskell.LSP.Messages

main = hspec $ do
  describe "manual session validation" $ 
    it "passes a test" $
      runSession "test/recordings/renamePass" $ do
        docItem <- getDocItem "Desktop/simple.hs" "haskell"
        docId   <- TextDocumentIdentifier <$> getDocUri "Desktop/simple.hs"

        sendNotification TextDocumentDidOpen (DidOpenTextDocumentParams docItem)

        skipMany loggingNotification

        NotPublishDiagnostics diagsNot <- notification

        liftIO $ diagsNot ^. params . diagnostics `shouldBe` List []
        
        sendRequest (Proxy :: Proxy DocumentSymbolRequest)
                    TextDocumentDocumentSymbol
                    (DocumentSymbolParams docId)

        RspDocumentSymbols rspSymbols <- response
        
        liftIO $ do
          let (List symbols) = fromJust (rspSymbols ^. result)
              mainSymbol = head symbols
          mainSymbol ^. name `shouldBe` "main"
          mainSymbol ^. kind `shouldBe` SkFunction
          mainSymbol ^. location . range `shouldBe` Range (Position 3 0) (Position 3 4)
          mainSymbol ^. containerName `shouldBe` Nothing
  
  describe "replay session" $
    it "passes a test" $
      replaySession "test/recordings/renamePass" `shouldReturn` True