# frozen_string_literal: true

module GraphQLMetrics
  module Instrumentation
    module_function

    def before_query(query)
      return if query.context[GraphQLMetrics::SKIP_GRAPHQL_METRICS_ANALYSIS]

      query.context.namespace(CONTEXT_NAMESPACE).tap do |ns|
        ns[GraphQLMetrics::TIMINGS_CAPTURE_ENABLED] = true
        ns[GraphQLMetrics::INLINE_FIELD_TIMINGS] = {}
        ns[GraphQLMetrics::LAZY_FIELD_TIMINGS] = {}
      end
    end

    def after_query(query)
      return if query.context[GraphQLMetrics::SKIP_GRAPHQL_METRICS_ANALYSIS]

      query.context.namespace(CONTEXT_NAMESPACE).tap do |ns|
        query_duration = GraphQLMetrics.current_time_monotonic - ns[GraphQLMetrics::QUERY_START_TIME_MONOTONIC]
        query_end_time = GraphQLMetrics.current_time

        runtime_query_metrics = {
          query_start_time: ns[GraphQLMetrics::QUERY_START_TIME],
          query_end_time: query_end_time,
          query_duration: query_duration,
          parsing_start_time_offset: ns[GraphQLMetrics::PARSING_START_TIME_OFFSET],
          parsing_duration: ns[GraphQLMetrics::PARSING_DURATION],
          validation_start_time_offset: ns[GraphQLMetrics::VALIDATION_START_TIME_OFFSET],
          validation_duration: ns[GraphQLMetrics::VALIDATION_DURATION],
        }

        analyzer = ns[GraphQLMetrics::ANALYZER_INSTANCE_KEY]
        analyzer.extract_query(runtime_query_metrics: runtime_query_metrics, context: query.context)
        analyzer.extract_fields_with_runtime_metrics(query.context)
      end
    end
  end
end