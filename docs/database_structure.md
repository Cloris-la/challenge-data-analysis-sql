# Database Structure Report

**Database**: `kbo_database.db`
**Generated on**: 2025-07-25 13:57:37
**Total Tables**: 9

## Table of Contents
- [`activity`](#activity)
- [`address`](#address)
- [`branch`](#branch)
- [`code`](#code)
- [`contact`](#contact)
- [`denomination`](#denomination)
- [`enterprise`](#enterprise)
- [`establishment`](#establishment)
- [`meta`](#meta)

## Table: `activity`

**Row Count**: 36,597,491

| Column Name | Data Type | Not Null | Default | Primary Key |
|-------------|-----------|----------|---------|-------------|
| `EntityNumber` | `TEXT` |  | `` |  |
| `ActivityGroup` | `INTEGER` |  | `` |  |
| `NaceVersion` | `INTEGER` |  | `` |  |
| `NaceCode` | `INTEGER` |  | `` |  |
| `Classification` | `TEXT` |  | `` |  |

**Indexes**:
- INDEX `EntityNumber`
  - Columns: `EntityNumber`

---

## Table: `address`

**Row Count**: 2,819,632

| Column Name | Data Type | Not Null | Default | Primary Key |
|-------------|-----------|----------|---------|-------------|
| `EntityNumber` | `TEXT` |  | `` |  |
| `TypeOfAddress` | `TEXT` |  | `` |  |
| `CountryNL` | `TEXT` |  | `` |  |
| `CountryFR` | `TEXT` |  | `` |  |
| `Zipcode` | `TEXT` |  | `` |  |
| `MunicipalityNL` | `TEXT` |  | `` |  |
| `MunicipalityFR` | `TEXT` |  | `` |  |
| `StreetNL` | `TEXT` |  | `` |  |
| `StreetFR` | `TEXT` |  | `` |  |
| `HouseNumber` | `TEXT` |  | `` |  |
| `Box` | `TEXT` |  | `` |  |
| `ExtraAddressInfo` | `TEXT` |  | `` |  |
| `DateStrikingOff` | `TEXT` |  | `` |  |

**Indexes**:
- INDEX ``
  - Columns: `EntityNumber`

---

## Table: `branch`

**Row Count**: 7,308

| Column Name | Data Type | Not Null | Default | Primary Key |
|-------------|-----------|----------|---------|-------------|
| `Id` | `TEXT` |  | `` |  |
| `StartDate` | `TEXT` |  | `` |  |
| `EnterpriseNumber` | `TEXT` |  | `` |  |

**Indexes**:
- INDEX `branch_EnterpriseNumber_idx`
  - Columns: `EnterpriseNumber`

---

## Table: `code`

**Row Count**: 21,500

| Column Name | Data Type | Not Null | Default | Primary Key |
|-------------|-----------|----------|---------|-------------|
| `Category` | `TEXT` |  | `` |  |
| `Code` | `TEXT` |  | `` |  |
| `Language` | `TEXT` |  | `` |  |
| `Description` | `TEXT` |  | `` |  |

**Indexes**:
- INDEX `code_Code_idx`
  - Columns: `Code`

---

## Table: `contact`

**Row Count**: 685,642

| Column Name | Data Type | Not Null | Default | Primary Key |
|-------------|-----------|----------|---------|-------------|
| `EntityNumber` | `TEXT` |  | `` |  |
| `EntityContact` | `TEXT` |  | `` |  |
| `ContactType` | `TEXT` |  | `` |  |
| `Value` | `TEXT` |  | `` |  |

**Indexes**:
- INDEX `contact_EntityNumber_idx`
  - Columns: `EntityNumber`

---

## Table: `denomination`

**Row Count**: 3,285,395

| Column Name | Data Type | Not Null | Default | Primary Key |
|-------------|-----------|----------|---------|-------------|
| `EntityNumber` | `TEXT` |  | `` |  |
| `Language` | `INTEGER` |  | `` |  |
| `TypeOfDenomination` | `INTEGER` |  | `` |  |
| `Denomination` | `TEXT` |  | `` |  |

**Indexes**:
- INDEX `denomination_EntityNumber_idx`
  - Columns: `EntityNumber`

---

## Table: `enterprise`

**Row Count**: 1,926,246

| Column Name | Data Type | Not Null | Default | Primary Key |
|-------------|-----------|----------|---------|-------------|
| `EnterpriseNumber` | `TEXT` |  | `` |  |
| `Status` | `TEXT` |  | `` |  |
| `JuridicalSituation` | `INTEGER` |  | `` |  |
| `TypeOfEnterprise` | `INTEGER` |  | `` |  |
| `JuridicalForm` | `REAL` |  | `` |  |
| `JuridicalFormCAC` | `REAL` |  | `` |  |
| `StartDate` | `TEXT` |  | `` |  |

**Indexes**:
- INDEX `enterprise_EnterpriseNumber_idx`
  - Columns: `EnterpriseNumber`

---

## Table: `establishment`

**Row Count**: 1,659,123

| Column Name | Data Type | Not Null | Default | Primary Key |
|-------------|-----------|----------|---------|-------------|
| `EstablishmentNumber` | `TEXT` |  | `` |  |
| `StartDate` | `TEXT` |  | `` |  |
| `EnterpriseNumber` | `TEXT` |  | `` |  |

**Indexes**:
- INDEX `EnterpriseNumber`
  - Columns: `EnterpriseNumber`
- INDEX `EstablishmentNumber`
  - Columns: `EstablishmentNumber`

---

## Table: `meta`

**Row Count**: 5

| Column Name | Data Type | Not Null | Default | Primary Key |
|-------------|-----------|----------|---------|-------------|
| `Variable` | `TEXT` |  | `` |  |
| `Value` | `TEXT` |  | `` |  |

---

