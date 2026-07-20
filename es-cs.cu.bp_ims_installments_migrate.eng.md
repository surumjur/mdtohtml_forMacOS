Product: Card Suite
Area: Issuing
Subarea: EUROBANK
Title: Eurobank Installment Migration Script
Subtitle: Migration
DocType: External specification
DocId:
Version: 1.0.0
Date: 2026-07-17
Confidential:

Disclaimer and notices
{: .heading}

While every attempt has been made to ensure that the information in this
document is accurate and complete, some typographical errors or
technical inaccuracies may exist. ***Tietoevry*** does not accept responsibility
for any kind of loss resulting from the use of information contained in this document.

The information contained in this document is subject to change without notice.
{: .pagebreakafter}

# Introduction

This document describes the purpose, input requirements, and business logic of the
`migrate_eb_installments.py` migration script used for ***Eurobank*** installment plan migration.

# Purpose

The script migrates installment plans from a CSV file into ***Card Suite***, creating the necessary
agreements and posting installment entries according to account-level configuration.

# Input File Columns

The input CSV file must contain the following columns:

| Column name          | Description                                                             |
| -------------------- | ----------------------------------------------------------------------- |
| `accountAgreementId` | The unique identifier for the account agreement to migrate.             |
| `installmentAmount`  | The total amount to be split into installments.                         |
| `numofInstallments`  | The number of installments for the plan – the rest of the installments. |
| `lastInstallment`    | The final installment amount because it is different from others.       |
| `merchantName`       | The name of the merchant.                                               |

The script will fail if any of these columns are missing.

# Due Date and Billing Date Logic

For each account agreement, the script retrieves 3 key values from the database:

**Business Date:** Current business date of the system.

**Billing Date:** The minimum value date from the account's CALA (Account Settlement Date Control)
book account.

**Due Day:** The due day is fetched from the account's effective conditions (condition index 102).
The due date is then constructed using the billing date — billing date + due days.

In case when next due date < next billing date, it is handled with `MIGR-SPEN-ACCNT-INSTP` event,
using `ANTRY_AMNT4` - amount debited in previous period/billing cycle (the billed (invoiced) part),
value date is current period end.

# Error Handling

The script checks that the installment amount is evenly divisible by the number of installments. This takes into consideration the final installment.
If not, the amount is rounded up from remainder if it is equal or higher to 5.

**Example:**

| Field                | Value   |
| -------------------- | ------- |
| `installmentAmount`  | 1000.00 |
| `numofInstallments`  | 3       |
| `lastInstallment`    | 333.34  |

Last installment (provided) = **333.34**
Regular installment = (1000.00 - 333.34) / (numofInstallments - 1) = **333.33**
Total = 333.33 × (numofInstallments - 1) + 333.34 = **1000.00**

The `lastInstallment` is part of `installmentAmount` — it is simply the final installment
that absorbs any rounding difference.

Any failed rows are logged and written to a separate file for review.

# Logging and Progress

The script logs all actions and errors to a log file.
Progress is displayed in the console during migration.

Revision history
{: .heading .revision-history}

| Version | Date       | Chapter        | Change                          |
| ------- | ---------- | -------------- | ------------------------------- |
| 1.0.0   | 2026-07-17 | All            | Initial version                 |
| 1.0.1   | 2026-07-17 | Input Columns, | Added `lastInstallment` field   |
|         |            | Error Handling |                                 |
