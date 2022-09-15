{% macro current_tests_run_results_query() %}
    with elementary_test_results as (
        select * from {{ ref('elementary', 'elementary_test_results') }}
    ),
    
    dbt_tests as (
        select * from {{ ref('elementary', 'dbt_tests') }}
    ),
    
    dbt_tests_with_elementary_unique_id as (
        select 
            case 
                when (alias = name and alias is not null and test_column_name is not null and short_name is not null) then test_column_name || '.' || alias || '.' || short_name
                when (alias = name and alias is not null and short_name is not null) then alias || '.' || short_name
                else unique_id
            end as elementary_unique_id,
            unique_id,
            database_name,
            schema_name,
            name,
            short_name,
            alias,
            test_column_name,
            severity,
            warn_if,
            error_if,
            test_params,
            test_namespace,
            tags,
            model_tags,
            model_owners,
            meta,
            depends_on_macros,
            depends_on_nodes,
            parent_model_unique_id,
            description,
            package_name,
            type,
            original_path,
            compiled_sql,
            path,
            generated_at   
        from dbt_tests
    ),
    
    dbt_tests_with_same_name_count as (
        select elementary_unique_id, count(*) as tests_name_count
        from dbt_tests_with_elementary_unique_id
        group by elementary_unique_id
    ),
    
    dbt_tests_with_final_unique_id as (
        select 
            case
                when counter.tests_name_count = 1 then tests.elementary_unique_id
                else tests.unique_id
            end as elementary_unique_id,
            tests.unique_id,
            tests.database_name,
            tests.schema_name,
            tests.name,
            tests.short_name,
            tests.alias,
            tests.test_column_name,
            tests.severity,
            tests.warn_if,
            tests.error_if,
            tests.test_params,
            tests.test_namespace,
            tests.tags,
            tests.model_tags,
            tests.model_owners,
            tests.meta,
            tests.depends_on_macros,
            tests.depends_on_nodes,
            tests.parent_model_unique_id,
            tests.description,
            tests.package_name,
            tests.type,
            tests.original_path,
            tests.compiled_sql,
            tests.path,
            tests.generated_at
        from dbt_tests_with_elementary_unique_id tests
        join dbt_tests_with_same_name_count counter on tests.elementary_unique_id = counter.elementary_unique_id
    ),
    
    elementary_test_results_with_elementary_unique_id as (
        select
            case 
                when (test_alias = test_node_name and test_alias is not null and column_name is not null and test_name is not null) then column_name || '.' || test_alias || '.' || test_name
                when (test_alias = test_node_name and test_alias is not null and test_name is not null) then test_alias || '.' || test_name
                else test_unique_id
            end as elementary_unique_id,
            id,
            data_issue_id,
            test_execution_id,
            test_unique_id,
            model_unique_id,
            detected_at,
            database_name,
            schema_name,
            table_name,
            column_name,
            test_type,
            test_sub_type,
            test_results_description,
            owners,
            tags,
            test_results_query,
            other,
            test_name,
            test_params,
            severity,
            status,
            test_node_name,
            test_alias
        from elementary_test_results
    ),
    
    elementary_test_results_with_final_unique_id as (
        select 
            case
                when counter.tests_name_count = 1 then results.elementary_unique_id
                else results.test_unique_id
            end as elementary_unique_id,
            results.id,
            results.data_issue_id,
            results.test_execution_id,
            results.test_unique_id,
            results.model_unique_id,
            results.detected_at,
            results.database_name,
            results.schema_name,
            results.table_name,
            results.column_name,
            results.test_type,
            results.test_sub_type,
            results.test_results_description,
            results.owners,
            results.tags,
            results.test_results_query,
            results.other,
            results.test_name,
            results.test_params,
            results.severity,
            results.status,
            results.test_node_name,
            results.test_alias
        from elementary_test_results_with_elementary_unique_id results
        join dbt_tests_with_same_name_count counter on results.elementary_unique_id = counter.elementary_unique_id
    ),
    
    first_time_test_occurred as (
        select 
            min(detected_at) as first_time_occurred,
            elementary_unique_id
        from elementary_test_results_with_elementary_unique_id
        group by elementary_unique_id
    )
    
    select
        test_results.id,
        test_results.data_issue_id,
        test_results.test_execution_id,
        test_results.elementary_unique_id as test_unique_id,
        test_results.model_unique_id,
        test_results.detected_at,
        test_results.database_name,
        test_results.schema_name,
        test_results.table_name,
        test_results.column_name,
        test_results.test_type,
        test_results.test_sub_type,
        test_results.test_results_description,
        test_results.owners,
        test_results.tags,
        test_results.test_results_query,
        test_results.other,
        test_results.test_name,
        test_results.test_params,
        test_results.severity,
        test_results.status,
        test_results.test_node_name,
        test_results.test_alias,
        first_occurred.first_time_occurred as test_created_at
    from elementary_test_results_with_final_unique_id test_results
    left join first_time_test_occurred first_occurred on test_results.elementary_unique_id = first_occurred.elementary_unique_id
{% endmacro %}