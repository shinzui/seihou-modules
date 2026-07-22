-- | Reference production telemetry resource. Both server and worker mains use
-- this bracket and thread the resulting metrics into their Keiro run options.
module Acme.Telemetry
  ( Telemetry (..),
    withTelemetry,
  )
where

import Acme.Prelude
import Control.Exception (bracket)
import Control.Monad (void)
import Keiro.Telemetry (KeiroMetrics, newKeiroMetrics)
import OpenTelemetry.Attributes qualified as Attributes
import OpenTelemetry.Metric qualified as Metric
import OpenTelemetry.Propagator (setGlobalTextMapPropagator)
import OpenTelemetry.Propagator.W3CBaggage (w3cBaggagePropagator)
import OpenTelemetry.Propagator.W3CTraceContext (w3cTraceContextPropagator)
import OpenTelemetry.Trace qualified as Trace

data Telemetry = Telemetry
  { tracer :: !Trace.Tracer,
    metrics :: !KeiroMetrics
  }

withTelemetry :: Text -> (Telemetry -> IO a) -> IO a
withTelemetry serviceName action = do
  setGlobalTextMapPropagator (w3cTraceContextPropagator <> w3cBaggagePropagator)
  bracket Trace.initializeGlobalTracerProvider flushAndShutdownTracerProvider $ \tracerProvider ->
    bracket Metric.initializeGlobalMeterProvider shutdownMeterProvider $ \meterProvider -> do
      let library = instrumentationLibrary serviceName
      tracer <- pure (Trace.makeTracer tracerProvider library Trace.tracerOptions)
      meter <- Metric.getMeter meterProvider library
      metrics <- newKeiroMetrics meter
      action Telemetry {tracer, metrics}

flushAndShutdownTracerProvider :: Trace.TracerProvider -> IO ()
flushAndShutdownTracerProvider provider = do
  void (Trace.forceFlushTracerProvider provider Nothing)
  void (Trace.shutdownTracerProvider provider Nothing)

shutdownMeterProvider :: Metric.MeterProvider -> IO ()
shutdownMeterProvider provider = void (Metric.shutdownMeterProvider provider Nothing)

instrumentationLibrary :: Text -> Trace.InstrumentationLibrary
instrumentationLibrary serviceName =
  Trace.InstrumentationLibrary
    { Trace.libraryName = serviceName,
      Trace.libraryVersion = "0.1.0.0",
      Trace.librarySchemaUrl = "",
      Trace.libraryAttributes = Attributes.emptyAttributes
    }

-- At both runtime assembly points:
--
--   withTelemetry "acme-server" $ \telemetry ->
--     runServer (serverOptions & #metrics .~ telemetry.metrics)
--
-- Inject the global TextMap propagator into outbound message metadata and
-- extract it before opening the worker span around message handling.
