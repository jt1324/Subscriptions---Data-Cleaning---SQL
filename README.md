# Subscriptions – Data Cleaning with SQL

A SQLite data cleaning project that uses the **6C data quality framework** to explore, standardise and validate subscription records.

The project builds a reusable cleaning pipeline, preserves the original data and flags inconsistent records for further review.

## Project Objectives

- Identify missing and inconsistent values.
- Standardise customer emails, subscription plans, countries and statuses.
- Normalise start dates and convert prices to numeric values.
- Keep the latest record for each subscription.
- Identify contradictions between related columns.
- Exclude test accounts from the final dataset.

## Tools and Techniques

- **SQLite**
- Common Table Expressions (CTEs)
- Conditional logic with `CASE`
- Text functions: `TRIM`, `LOWER`, `UPPER`, `SUBSTR` and `LIKE`
- Type conversion with `CAST` and inspection with `typeof`
- Date formatting with `date()`
- Missing-value handling with `COALESCE`
- Deduplication with `ROW_NUMBER()`
- Table creation with `CREATE TABLE AS`

## Dataset

The source table, `subscriptions`, contains:

- Subscription and customer identifiers
- Customer email and country
- Subscription plan and monthly price
- Subscription status, start date and end date
- Payment method
- Last update timestamp
- Internal notes

## The 6C Data Quality Framework

### 1. Completeness

Check for blank emails, dates and payment methods. Replace payment-method placeholders such as `'NULL'`, `'N/A'` and empty strings with `Unknown`.

### 2. Consistency

- Trim whitespace and lowercase customer emails.
- Standardise plan capitalisation.
- Map country variations to consistent names.
- Group subscription statuses into Active, Cancelled and Paused.
- Convert supported start-date formats (`YYYY-MM-DD` and `DD/MM/YYYY`) to `YYYY-MM-DD`.

### 3. Correctness

Convert `monthly_price` to `REAL` and apply the project's assumed correction rules:

- Convert negative prices to positive values.
- Divide prices greater than 100 by 100.

These rules assume the values represent sign or decimal-placement errors and should be confirmed against the business context before reuse.

### 4. Conformity

Enforce one row per `subscription_id` using `ROW_NUMBER()`. Retain the record with the latest `updated_at` value.

### 5. Coherence

Create a `quality_flag` to identify:

- Active subscriptions with an end date.
- Cancelled subscriptions without an end date.
- Paid plans with no charges.
- Free plans with positive charges.
- Basic plans priced differently from 9.99.
- Premium plans priced differently from 19.99.

Each row receives the first matching flag, or `ok` when no rule matches. Flagged records remain in the output for review.

### 6. Contextual Relevance

Exclude records whose customer email starts with `test` to focus the output on non-test accounts. Missing emails are not removed by this filter.

## Final Cleaning Pipeline

The final query combines the cleaning steps into a sequence of CTEs and creates `subscriptions_clean`.

The output contains the cleaned subscription fields and the additional `quality_flag` column.

**The original `subscriptions` table remains unchanged. Running the pipeline replaces any existing `subscriptions_clean` table.**

## How to Run

1. Open a SQLite database containing the populated `subscriptions` table.
2. Run the exploratory queries to inspect the data.
3. Execute the **Final Cleaning Pipeline** section.
4. Review the output:

```sql
SELECT *
FROM subscriptions_clean;
```

To inspect records requiring further attention:

```sql
SELECT *
FROM subscriptions_clean
WHERE quality_flag <> 'ok';
```

## Assumptions and Limitations

- Broad country and status matching can misclassify values. For example, `%active%` also matches `inactive`.
- Missing-value checks do not cover every SQL `NULL` or placeholder variation.
- Ordering by `updated_at` assumes consistently formatted timestamps.
- Prices use floating-point `REAL`, not fixed-precision decimal storage.
- The initial revenue summary uses uncleaned data; the script does not calculate a final validated monthly recurring revenue figure.
