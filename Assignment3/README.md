# DBS1 Assignment 3 - Mapping EER to Relations

---

## Hvad er dette assignment?
Vi tager vores EER diagram fra Assignment 2 og oversætter det til rigtige databasetabeller.
Derefter tjekker vi om tabellerne er godt designet via normalisering (1NF, 2NF, 3NF).

---

## Task A - Strong and Weak Entities

> **Stærk entitet** = eksisterer alene med sin egen PK
> **Svag entitet** = kan ikke eksistere uden en anden entitet — låner PK fra den stærke

**Strong entities:**

| Entity | Begrundelse |
|---|---|
| ToyStore | Eksisterer uafhængigt med store_id |
| Department | Eksisterer uafhængigt med dept_id |
| Employee | Eksisterer uafhængigt med employee_id |
| Product | Eksisterer uafhængigt med sku |
| Receipt | Eksisterer uafhængigt med receipt_id |
| Promotion | Eksisterer uafhængigt med promotion_id |

**Weak entities:**

| Entity | Afhænger af | Begrundelse |
|---|---|---|
| Stock | ToyStore + Product | "5 stk på lager" giver ingen mening uden butik og produkt |
| ReceiptLine | Receipt | En kvitteringslinje eksisterer ikke uden en kvittering |

**Relationer:**

ToyStore(store_id PK, name)

Department(dept_id PK, dept_name, store_id FK → ToyStore)

Employee(employee_id PK, first_name, last_name, hiring_date, anniversary_date, dept_id FK → Department)

Product(sku PK, needs_batteries)

Receipt(receipt_id PK, header, store_id FK → ToyStore)

Promotion(promotion_id PK, code, discount)

Stock(store_id PPK FK → ToyStore, sku PPK FK → Product, receival_time, street, zip_code, quantity)

ReceiptLine(receipt_id PPK FK → Receipt, line_number PPK, quantity, price, sku FK → Product, promotion_id FK → Promotion)

---

## Task B - 1:* Relationships

> **1:*** = én til mange — FK placeres ALTID på mange-siden
> Eksempel: Department "husker" hvilken butik den tilhører via store_id FK

| Relation | FK placering |
|---|---|
| ToyStore 1:* Department | Department.store_id → ToyStore |
| ToyStore 1:* Receipt | Receipt.store_id → ToyStore |
| Department 1:* Employee | Employee.dept_id → Department |
| Receipt 1:* ReceiptLine | ReceiptLine.receipt_id → Receipt |
| Product 1:* ReceiptLine | ReceiptLine.sku → Product |
| Product 1:* Stock | Stock.sku → Product |
| ToyStore 1:* Stock | Stock.store_id → ToyStore |

---

## Task C - 1:1 Relationships

> **1:1** = én til én — FK kan placeres på enten side
> Participation afgør hvor FK placeres:
> - **Total** = SKAL have en relation (scenariet siger "must/always/every")
> - **Partial** = KAN have en relation (scenariet siger "may/optionally/some")

**Manager styrer Department (1:1)**

- Department: total — hver afdeling HAR altid en manager
- Manager: total — en manager styrer altid én afdeling

Begge total → FK placeres på enten side. Vi vælger Department:

Department(dept_id PK, dept_name, store_id FK → ToyStore, manager_id FK → Employee)

**Huskeregel participation:**
- Begge total → FK på enten side
- Én partial → FK på den partial side (kan være NULL)
- Begge partial → FK på enten side med NULL tilladt

---

## Task E - *:* Relationships

> ***:*** = mange til mange — løses ALTID med en junction tabel
> Eksempel: én bundle indeholder mange produkter, ét produkt kan være i mange bundles

**Product *:* Product (Bundle — rekursiv)**

En bundle er selv et produkt der indeholder andre produkter → rekursiv relation

Bundle(bundle_sku PPK FK → Product, product_sku PPK FK → Product)

**Junction tabel:**
- bundle_sku = det produkt der ER en bundle
- product_sku = det produkt der er INDEHOLDT i bundlen
- Kombinationen er PPK — samme produkt kan indgå i mange bundles

---

## Task D - Superclass/Subclass

> **Superclass** = den generelle klasse (Employee)
> **Subclass** = den specifikke klasse der arver fra superclass (Manager, Cashier, Buyer)
> Subtypes arver alle attributter fra superclass

Employee → Manager, Cashier, Buyer — **Total, Disjoint**

**Constraints:**
- **Disjoint** = én employee kan KUN være én subtype (enten manager, cashier ELLER buyer)
- **Total** = alle employees SKAL tilhøre en subtype — ingen "generisk" employee

**Mapping — Total + Disjoint → én tabel per subtype:**

Employee(employee_id PK, first_name, last_name, hiring_date, anniversary_date, dept_id FK → Department, employee_type)

Manager(employee_id PK FK → Employee, discount)

Cashier(employee_id PK FK → Employee, is_certified)

Buyer(employee_id PK FK → Employee)

**Huskeregel constraints:**
- Total + Disjoint → én tabel per subtype (renest, ingen NULL)
- Partial → én stor tabel med NULL i subtype-kolonner
- Overlapping → én stor tabel med boolean kolonner per subtype

---

## Task F - Komplekse relationer og multivaluerede attributter

> **Kompleks relation** = forbinder 3+ tabeller på én gang (ternær)
> **Multivalueret attribut** = én attribut med flere værdier (løses med separat tabel)

**Komplekse relationer:**
Ingen — alle relationer i modellen er binære (forbinder kun 2 tabeller)

**Multivaluerede attributter:**
toy_specialization på Buyer kan have op til 3 værdier (LEGO, Puzzles, Dolls)

Problem: kan ikke gemme flere værdier i én celle!

Løsning — separat tabel:

BuyerSpecialization(employee_id PPK FK → Buyer, toy_specialization PPK)

---

## Task G - Normalisering

> Normalisering er 3 regler der sikrer godt tabeldesign
> Alle 3 skal være opfyldt — man starter med 1NF og arbejder sig op

**1NF — Hver celle må kun have én værdi:**

> Problem: toy_specialization = "LEGO, Puzzles, Dolls" → flere værdier i én celle!
> Fix: BuyerSpecialization tabel (én række per specialisering)

- toy_specialization → BuyerSpecialization tabel ✓
- receival_address → splittet til street, city, zip_code ✓
- Alle tabeller har primærnøgle ✓
- **Konklusion: Alle tabeller er i 1NF ✓**

**2NF — Alle ikke-nøgle attributter afhænger af HELE PK:**

> Kun relevant for tabeller med sammensat PK (PPK)
> Ikke-nøgle attribut = en kolonne der ikke er PK eller FK — bare en normal kolonne

- Stock: quantity, receival_time, street, zip_code afhænger alle af store_id + sku ✓
- ReceiptLine: quantity, price afhænger af receipt_id + line_number ✓
- **Konklusion: Alle tabeller er i 2NF ✓**

**3NF — Ikke-nøgle attributter afhænger KUN af PK:**

> Problem: zip_code → city (postnummer bestemmer by — transitiv afhængighed!)
> city afhænger af zip_code, ikke af PK

Fix:

Stock(store_id PPK, sku PPK, receival_time, street, zip_code, quantity)

ZipCode(zip_code PK, city)

- Alle andre tabeller har ingen transitive afhængigheder ✓

**Samlet konklusion normalisering:**
- 1NF: Fixet ved at flytte toy_specialization til BuyerSpecialization tabel
- 2NF: Alle tabeller var allerede i 2NF — ingen partielle afhængigheder
- 3NF: Fixet ved at flytte city til ZipCode tabel (fjernede zip_code → city)
- Alle tabeller er nu i 3NF ✓

- **Konklusion: Alle tabeller er i 3NF ✓**

---

## Task H - Samlet relationsschema

> Dette er det endelige resultat — alle tabeller samlet på ét sted

ToyStore(store_id PK, name)

Department(dept_id PK, dept_name, store_id FK → ToyStore, manager_id FK → Employee)

Employee(employee_id PK, first_name, last_name, hiring_date, anniversary_date, dept_id FK → Department, employee_type)

Manager(employee_id PK FK → Employee, discount)

Cashier(employee_id PK FK → Employee, is_certified)

Buyer(employee_id PK FK → Employee)

BuyerSpecialization(employee_id PPK FK → Buyer, toy_specialization PPK)

Product(sku PK, needs_batteries)

Bundle(bundle_sku PPK FK → Product, product_sku PPK FK → Product)

Stock(store_id PPK FK → ToyStore, sku PPK FK → Product, receival_time, street, zip_code, quantity)

ZipCode(zip_code PK, city)

Receipt(receipt_id PK, header, store_id FK → ToyStore)

ReceiptLine(receipt_id PPK FK → Receipt, line_number PPK, quantity, price, sku FK → Product, promotion_id FK → Promotion)

Promotion(promotion_id PK, code, discount)
