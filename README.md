<!-- Profile README: paste into github.com/Jdominguezzz/Jdominguezzz -->
# Hi, I'm João

**Marketing & BI analyst who builds the pipelines behind the numbers.** I take marketing and customer data from raw source to a decision someone can act on, and I test the data before I trust it.

MSc Data-Driven Marketing (NOVA IMS, Lisbon, in progress) · years managing retail operations, so I read data the way a store manager does: stock, staff, conversion and returns.

Before data: 7 years in Benfica and Sporting's football academies, then founded a nonprofit that raised €145K through campaigns I planned and measured.

---

### 📌 Featured: [marketing-roi-pipeline](https://github.com/Jdominguezzz/marketing-roi-pipeline)

**Question:** which marketing channels bring in sellers who actually generate revenue, not just cheap leads?

An end-to-end ELT pipeline on public Olist marketplace data. It follows **8,000 leads → 842 won sellers → their orders**, and calculates CAC and 3-month LTV:CAC by acquisition channel.

| Paid channel | Cost per lead | Lead → seller | CAC | LTV:CAC (3 mo) |
|---|---|---|---|---|
| Paid search | €15.6 | 12.3% | €127 | 0.094 |
| Paid social | €11.5 | 5.6% | €207 | 0.028 |

**So what:** paid social *looks* 26% cheaper per lead, but converts at less than half the rate, so each seller costs 63% more. Neither channel pays back within 3 months, but paid search recovers **3.4× more revenue per euro of acquisition cost**. Ranking channels by cost per lead points the budget the wrong way, and the best-converting leads have no tracked channel, so attribution needs fixing first.

*Conversions and revenue are real Olist data; ad spend is simulated (Olist doesn't publish it). Assumptions are documented in the repo's decision records.*

`Python · DuckDB · dbt · Dagster · GitHub Actions` · 32 scheduled assets · 84 automated tests incl. reconciliation · CI on every PR

---

### 🔨 Also built

- **[retail-shift-report](https://github.com/Jdominguezzz/retail-shift-report)**: a small Python tool I use in my own job. It turns weekly shift files into staffing and overtime summaries.

### 🚧 In progress

- **GA4 measurement & funnel audit** (Google Merchandise Store): can this store trust its analytics, and where does its funnel lose money? → [marketing-analytics-portfolio](https://github.com/Jdominguezzz/marketing-analytics-portfolio)
- **Customer journeys → conversion** (MSc thesis): which omnichannel journeys in fashion retail predict a purchase?

### 🛠️ Toolkit

| | |
|---|---|
| **Data engineering** | Python · SQL · DuckDB · dbt · Dagster · Git / GitHub Actions |
| **Analytics, BI & ML** | Power BI · Power Query · Excel · pandas · scikit-learn · PySpark · KNIME |
| **Marketing** | GA4 · BigQuery · Looker Studio · Meta Ads · Google Ads · HubSpot · SEO tooling |

### 🧭 How I work

1. **Audit the data first.** A good model on bad data is still wrong.
2. **Tie every metric to a decision.** If nobody would act on it, it's a vanity metric.
3. **Say what's real and what's assumed.** Simulated inputs, sample sizes and limits are written down, not hidden.

### 📫 Contact

[LinkedIn](https://www.linkedin.com/in/joaopedrodominguesin) · Lisbon · open to Business / BI / Analytics Engineering roles.

---

<sub>Every project here starts with a business question and ends with a decision.</sub>
