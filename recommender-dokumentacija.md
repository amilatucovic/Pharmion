# Implementacija sistema preporuke – Pharmion

## Uvod

U savremenim digitalnim sistemima, personalizacija predstavlja ključni faktor za poboljšanje korisničkog iskustva i povećanje angažmana korisnika. Umjesto prikazivanja generičkog sadržaja, sistemi preporuke omogućavaju svakom korisniku da dobije sadržaj prilagođen njegovim potrebama, interesima i ponašanju.

U kontekstu Pharmion aplikacije, personalizacija ima poseban značaj jer pomaže pacijentima da:

 - lakše pronađu relevantne suplemente za svoje zdravlje
 - otkriju proizvode koje inače ne bi sami pretraživali
 - donesu informisanije odluke

Time se ne poboljšava samo korisničko iskustvo, već i:

 - povećava vjerovatnoća rezervacije proizvoda
 - jača povjerenje korisnika u aplikaciju
 - optimizuje prikaz ponude bez preopterećenja korisnika

Zbog toga je implementiran sistem preporuke zasnovan na mašinskom učenju, koji automatski prilagođava preporuke svakom pacijentu.


## Opis sistema

Pharmion aplikacija implementira sistem preporuke suplementa za pacijente zasnovan na **kolaborativnom filtriranju** (Collaborative Filtering) putem **matrične faktorizacije** (Matrix Factorization) koristeći **ML.NET** biblioteku.

Cilj sistema je predložiti pacijentima suplemente koje još nisu rezervisali, a koje su drugi korisnici sa sličnim obrascima rezervacija često rezervisali zajedno. Na ovaj način aplikacija personalizuje iskustvo svakog pacijenta i pomaže mu u otkrivanju novih suplementa relevantnih za njegovo zdravlje.

---

## Putanja do source code-a

```
pharmion-backend/Pharmion.Services/Services/RecommendationService.cs
```

---

## Algoritam

### Tip modela
- **MatrixFactorizationTrainer** (ML.NET)
- **Gubitak (Loss Function):** `SquareLossOneClass` – pogodan za implicit feedback gdje label uvijek iznosi 1 (korisnik je rezervisao suplement)
- **Broj iteracija:** 100
- **ApproximationRank:** 32
- **Alpha:** 0.01
- **Lambda:** 0.025
- **C:** 0.00001

### Princip rada
Model uči na osnovu **co-rezervacija** – koji su suplementi bili rezervisani zajedno od strane istih pacijenata. Ako su pacijent A i pacijent B rezervisali iste suplemente, smatra se da su njihovi profili slični i sistem može preporučiti pacijentu A suplemente koje je pacijent B rezervisao, a pacijent A još nije.

---

## Tok sistema preporuke

### 1. Učitavanje ili treniranje modela

Prilikom prvog zahtjeva za preporukama, sistem provjerava postoji li već istrenirani model:

- Ako datoteka `supplement_model.zip` **postoji** → model se učitava iz fajla i odmah koristi
- Ako **ne postoji** → sistem automatski trenira novi model na osnovu historijskih podataka i sprema ga

```
supplement_model.zip  ←→  korijen WebAPI projekta
```

Model se trenira samo jednom i koristi se za sve naredne zahtjeve bez ponovnog treniranja (lazy load).

---

### 2. Priprema podataka za treniranje

Sistem dohvata sve rezervacije suplementa iz baze, grupisane po pacijentima:

```
ReservationItems
  WHERE Product.Type == Supplement
  GROUP BY PatientId
```

Za svakog pacijenta koji je rezervisao više suplementa, generišu se **parovi co-rezervacija**:

```
Za pacijenta koji je rezervisao suplemente [S1, S2, S3]:
  → (S1, S2, label=1)
  → (S1, S3, label=1)
  → (S2, S1, label=1)
  → (S2, S3, label=1)
  → (S3, S1, label=1)
  → (S3, S2, label=1)
```

Svaki par znači: *"Suplement X i suplement Y su bili rezervisani od strane istog pacijenta"*.

Ako nema dovoljno podataka za treniranje (niti jedan pacijent nema dvije ili više rezervacija suplementa), model se ne trenira i sistem prelazi na **fallback logiku**.

---

### 3. Generisanje preporuka

Kada pacijent zatraži preporuke:

1. **Dohvati suplemente koje je pacijent već rezervisao** (`reservedIds`)
2. **Dohvati sve aktivne suplemente** iz baze
3. **Filtriraj kandidate** – isključi suplemente koje je pacijent već rezervisao
4. **Izračunaj score** za svaki kandidat koristeći ML model:
   - Za svaki suplement koji je pacijent već rezervisao, model predviđa score sličnosti sa svakim kandidatom
   - Scoreovi se akumuliraju po kandidatu (sumiraju se predviđanja za sve rezervisane suplemente)
5. **Sortiraj** kandidate po ukupnom score-u (opadajuće)
6. **Vrati Top 5** preporuka

---

### 4. Cold Start – novi pacijenti

Ako pacijent **nema niti jednu rezervaciju suplementa**, sistem prelazi na fallback logiku:

- Prikazuju se **najpopularniji suplementi** – oni koji su najčešće rezervisani od strane svih pacijenata
- Isključuju se suplementi koje je pacijent već rezervisao (u ovom slučaju nema ih)
- Ako ni popularni suplementi nisu dostupni, vraća se prvih 5 aktivnih suplementa

```
ReservationItems
  WHERE Product.Type == Supplement
  GROUP BY ProductId
  ORDER BY COUNT DESC
  TAKE 5
```

---

## ML modeli i entiteti

### `SupplementEntry` – ulazni podaci za model

| Polje | Tip | Opis |
|---|---|---|
| `SupplementId` | `uint` | ID suplementa koji je pacijent rezervisao |
| `CoReservedSupplementId` | `uint` | ID suplementa koji je bio rezervisan zajedno |
| `Label` | `float` | Uvijek 1 (pozitivna interakcija) |

### `SupplementPrediction` – izlaz modela

| Polje | Tip | Opis |
|---|---|---|
| `Score` | `float` | Predviđeni score sličnosti (veći = relevantniji) |

---

## API endpoint

```
GET /Recommendation/{patientId}
```

- **Autorizacija:** `[Authorize(Roles = "Patient")]`
- **Ownership provjera:** `patientId` mora odgovarati `userId` iz JWT tokena
- **Response:** Lista `RecommendationResponse` objekata

### `RecommendationResponse`

```json
{
  "product": {
    "id": 5,
    "name": "Magnezij 400 mg",
    "typeName": "Supplement",
    "price": 11.50,
    "imageUrl": "..."
  },
  "score": 0.87,
  "reason": "Recommended because patients who reserved Vitamin C 1000mg and Probiotic Complex also reserved this supplement."
}
```

---

## Prikaz u mobilnoj aplikaciji

Preporuke su dostupne u **Products** screenu, u tabu **"For You"**:

- Prikazuju se kao kartice sa slikom, nazivom, cijenom i razlogom preporuke
- Ispod svake preporuke prikazuje se personalizovani razlog koji navodi konkretne suplemente iz historije pacijenta koji su bili osnova za preporuku, npr.: *"Recommended because patients who reserved Vitamin C 1000mg and Probiotic Complex also reserved this supplement."*
- U slučaju fallback preporuka (popularni suplementi): *"Popular supplement among our users"*
- Svaka kartica sadrži dugme **"Find in Pharmacy"** koje otvara bottom sheet sa listom apoteka u pacijentovom gradu gdje je suplement dostupan

---


## Tehnologije

| Komponenta | Tehnologija |
|---|---|
| Backend | .NET 9 / C# |
| ML biblioteka | ML.NET |
| Algoritam | MatrixFactorizationTrainer |
| Baza podataka | SQL Server (EF Core) |
| Mobilna aplikacija | Flutter |
| Model persistence | `supplement_model.zip` |