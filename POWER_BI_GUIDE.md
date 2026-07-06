# Guide: building the dashboard in Power BI

This assumes you already have Power BI Desktop installed. The file
`data_for_powerbi.xlsx` (in this same folder) has 4 sheets, one per table in
the model — they're already clean, no need to transform them again.

---

## 1. Import the data

1. Power BI Desktop → **Get Data** → **Excel**.
2. Select `data_for_powerbi.xlsx` → check all 4 sheets (`fact_sales`,
   `dim_customer`, `dim_product`, `dim_date`) → **Transform Data**.
3. In Power Query Editor, double-check these types (Power BI sometimes
   guesses wrong):
   - `fact_sales`: `order_date`/`ship_date` → Date; `sales`, `profit`,
     `profit_margin`, `discount` → Decimal Number; `quantity`, `ship_days` →
     Whole Number.
   - `dim_date`: `date` → Date; `date_id`, `year`, `month`, `quarter` →
     Whole Number.
4. **Close & Apply**.

## 2. Data model (star schema)

In the **Model** view, build these relationships (drag from one field to
the other):

```
        dim_customer                   dim_product
       customer_id (1) ─────┐     ┌───── product_id (1)
                             ▼     ▼
                         fact_sales (many)
                             ▲
                             │
                        date_id (1)
                             │
                         dim_date
```

- `dim_customer[customer_id]` (1) → `fact_sales[customer_id]` (many)
- `dim_product[product_id]` (1) → `fact_sales[product_id]` (many)
- `dim_date[date_id]` (1) → `fact_sales[date_id]` (many)

All single-direction (dimension filters the fact table). This is the exact
same model you already built in SQL — same design, two different tools. If
you get asked in an interview "why a star schema instead of one flat
table?", this is your answer: faster relationships, simpler measures, and
it's the industry standard.

## 3. DAX measures

Create a new empty table called `_Measures` (Modeling → New table →
`_Measures = ROW("x", 0)`) to keep measures organized and separate from data
columns. Then **New Measure** for each of these:

```DAX
Total Sales = SUM(fact_sales[sales])

Total Profit = SUM(fact_sales[profit])

Margin % =
DIVIDE([Total Profit], [Total Sales], 0)

Unique Orders = DISTINCTCOUNT(fact_sales[order_id])

Average Order Value =
DIVIDE([Total Sales], [Unique Orders], 0)

Prior Year Sales =
CALCULATE([Total Sales], SAMEPERIODLASTYEAR(dim_date[date]))

YoY Growth % =
DIVIDE([Total Sales] - [Prior Year Sales], [Prior Year Sales], 0)

Sales YTD =
TOTALYTD([Total Sales], dim_date[date])

Customer Rank =
RANKX(ALL(dim_customer[customer_name]), [Total Sales], , DESC)
```

Quick notes:
- Use `DIVIDE()` instead of `/` to avoid divide-by-zero errors.
- `SAMEPERIODLASTYEAR` and `TOTALYTD` need `dim_date[date]` marked as a
  **date table** (right-click `dim_date` → *Mark as date table* → column
  `date`).

## 4. Useful calculated columns

```DAX
fact_sales[Discount Range] =
SWITCH(
    TRUE(),
    fact_sales[discount] = 0, "No discount",
    fact_sales[discount] <= 0.15, "Low (1-15%)",
    fact_sales[discount] <= 0.30, "Medium (16-30%)",
    "High (>30%)"
)
```

## 5. Suggested dashboard pages

### Page 1 — Executive summary
- 4 KPI cards at the top: **Total Sales**, **Total Profit**, **Margin %**,
  **Unique Orders**.
- Line chart: `Total Sales` by `dim_date[year_month]` (monthly trend).
- Bar chart: `Total Sales` by `dim_product[category]`.
- Horizontal bar chart: `Total Sales` by `dim_customer[region]`.
- Slicers at the top: `year`, `segment`.

### Page 2 — Profitability and discounts
- Bar chart: `Margin %` by `Discount Range` (this is your main insight — it
  shows margin turning negative above a 30% discount).
- Table: top 10 products by `Total Profit`.
- Treemap: `Total Sales` by `category` → `subcategory`.

### Page 3 — Customers
- Table/matrix: customers by `Total Sales`, with `Customer Rank`.
- Donut chart: `Total Sales` by `segment`.
- Card: customers with a single order (possible churn risk — the same
  question you already answered in SQL with query 10).

## 6. What the result looks like with this data

These are the real numbers that came out of your Python cleaning step —
you'll recognize them on your dashboard:

| Metric | Value |
|---|---|
| Total sales | $46,124,858 MXN |
| Total profit | $12,111,150 MXN |
| Overall margin | 26.3% |
| Unique orders | 2,200 |
| Leading category by sales | Technology ($28.4M) |
| Leading region | North ($14.3M) |
| Margin at >30% discount | **-12.6%** (a loss) |

## 7. Final tips

- Use a palette of 2-3 colors max, consistent across all pages.
- KPI cards go top-left (that's where the eye lands first).
- Don't use pie charts with more than 4-5 categories — use bars instead.
- Publish the report (Power BI Service) or export to PDF for your
  portfolio; a link to a published (read-only) report is more convincing on
  a resume than a screenshot.
