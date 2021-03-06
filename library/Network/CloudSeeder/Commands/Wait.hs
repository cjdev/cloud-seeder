module Network.CloudSeeder.Commands.Wait
  ( waitCommand
  ) where

import Control.Lens ((^.))
import Control.Monad.Error.Lens (throwing)
import Control.Monad.Logger (MonadLogger, logInfoN)

import qualified Data.Text as T

import Network.CloudSeeder.Commands.Shared
import Network.CloudSeeder.DSL
import Network.CloudSeeder.Error
import Network.CloudSeeder.Monads.AWS

waitCommand :: (AsCliError e, MonadCloud e m, MonadLogger m)
  => m (DeploymentConfiguration m) -> T.Text -> T.Text -> m ()
waitCommand mConfig nameToWaitFor env = do
  config <- mConfig
  let appName = config ^. name
      stackName = mkFullStackName env appName nameToWaitFor
  waitOnStack stackName
  waitedOnStack <- describeStack stackName
  stackInfo <- maybe
    (throwing _CliCloudError (CloudErrorInternal "stack did not exist after wait"))
    pure
    waitedOnStack
  logInfoN =<< toYamlText stackInfo "Stack"
