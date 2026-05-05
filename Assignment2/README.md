# DBS1 Assignment 2 - ER/EER Toy Store

## Task A - Entities

| Entity | Hvor i scenariet |
|---|---|
| ToyStore | "each toy store has a jolly name" |
| Department | "several departments (e.g. Games or Dolls)" |
| Employee | "Employees work in one department" |
| Manager | "Employees are either managers, cashiers, or buyers" |
| Cashier | "A cashier may be certified to handle cash" |
| Buyer | "A buyer has a toy specialization" |
| Product | "Each product has a sku number" |
| Bundle | "Some products are bundles that contain other products" |
| Stock | "Stock is tracked per toy store" |
| Receipt | "The toy store issues receipts" |
| ReceiptLine | "A receipt has a header and receipt lines" |
| Promotion | "Optionally a promotion can apply" |

## Task B - Attributter og primærnøgler

**ToyStore**
- store_id {PK}
- name

**Department**
- dept_id {PK}
- dept_name

**Employee**
- employee_id {PK}
- name (COMPOSITE: first_name, last_name)
- hiring_date
- anniversary_date (DERIVED: hiring_date + 5 år)

**Manager** (subtype af Employee)
- discount

**Cashier** (subtype af Employee)
- is_certified

**Buyer** (subtype af Employee)
- toy_specialization (MULTIVALUED, max 3 værdier)

**Product**
- sku {PK}
- needs_batteries

**Stock**
- store_id {PPK}
- sku {PPK}
- receival_time
- receival_address (COMPOSITE: street, city, zip_code)
- quantity

**Receipt**
- receipt_id {PK}
- header

**ReceiptLine**
- receipt_id {PPK}
- line_number {PPK}
- quantity
- price

**Promotion**
- promotion_id {PK}
- code
- discount

**Composite attributter:**
- name på Employee (first_name + last_name)
- receival_address på Stock (street + city + zip_code)

**Derived attribut:**
- anniversary_date på Employee — udregnes fra hiring_date + 5 år

## Task C - Relationer og multiplicitet

- ToyStore ||--o{ Department : én butik har mange afdelinger
- ToyStore ||--o{ Stock : én butik sporer mange stock-rækker
- ToyStore ||--o{ Receipt : én butik udsteder mange kvitteringer
- Department ||--o{ Employee : én afdeling har mange ansatte
- Manager ||--|| Department : én manager styrer én afdeling
- Employee ||--o| Manager : en employee er enten manager...
- Employee ||--o| Cashier : ...cashier...
- Employee ||--o| Buyer : ...eller buyer
- Product ||--o{ Stock : ét produkt findes i mange stock-rækker
- Product ||--o{ Bundle : rekursiv - bundle indeholder andre products
- Receipt ||--o{ ReceiptLine : én kvittering har mange linjer
- ReceiptLine }o--|| Product : én linje beskriver ét produkt
- ReceiptLine }o--o| Promotion : én linje kan anvende én promotion

**Rekursiv relation:**
Product indeholder Product via BUNDLE-tabellen. En Bundle er selv et
Product der indeholder andre Products. Valgt fordi scenariet siger
"Some products are bundles that contain other products."

## Task D - Specialisering/Generalisering

**Employee → Manager, Cashier, Buyer**
- Disjoint (d): En medarbejder kan KUN være én af de tre typer
- Total: Alle employees SKAL tilhøre én subtype
- Scenariet siger "Employees are either managers, cashiers, or buyers"

**Product → Bundle**
- Partial: Ikke alle products er bundles
- Disjoint: En Bundle er stadig et Product og arver sku og needs_batteries
- Scenariet siger "Some products are bundles"

## Task E - Aggregation og Composition

**Composition (stærk afhængighed):**
- ToyStore → Department: En afdeling kan ikke eksistere uden en butik
- Receipt → ReceiptLine: En kvitteringslinje kan ikke eksistere uden en kvittering

**Aggregation (svag afhængighed):**
- Stock: Er en aggregation af ToyStore og Product. Begge eksisterer uafhængigt
- ReceiptLine → Promotion: En promotion eksisterer uafhængigt af om den bruges

## Task F - Diagram
Se vedlagt fil: UML assignment 2 DBS.pdf
