# news-manager
NewsManager è un Smart Contract realizzato per Start2Impact University. 

Indirizzo del contratto [Sepolia Testnet]: 0xe140384C27f41C0f7dd30713e763e1bD94E90A35

Lo smart contract ha lo scopo gestire il processo di pubblicazione e la validazione delle notizie online, certificandone la validità per mezzo la tecnologia Blockchain e automatizzando i pagamenti verso gli utenti validatori.

Il contratto utilizza una struct per il modello dati delle news (News) e una libreria la gestione dei validatori e della validazione (NewsUtils). Capiamo da cosa è composto ed in seguito capiremo come utilizzarlo al meglio.

 <font size="4">**Sommario delle variabili e strutture**</font>

Lo NewsManager ha la seguenti variabili storage

	uint balance (built-in)
	address owner
	address[] validators
    uint totalRewards
    uint currentReward
	uint currentPrice
    uint currentReportsRequired
	mapping (address => uint) validatorRewards
    mapping (address => uint) validatorReports 
	News[] news

dove:
- **balance** è il bilancio del contratto
- **owner** è il proprietario del contratto
- **validators** rappresenta la lista degli utenti validatori
- **totalRewards** rappresenta il valore totale di ricompensa assegnata complessivamente a tutti i validatori
- **currentReward** rappresenta il valore attuale di ricompensa da assegnare ad ogni validatore
- **currentPrice** rappresenta il valore in wei da inviare al contratto per aggiungere un utente alla lista dei validatori
- **currentReportsRequired** rappresenta la quantità di segnalazioni necessarie per bannare un validatore
- **validatorRewards** è una mappa che traccia la quantità di ETH ricevuti come ricompensa per ciascun validatore
- **validatorReports** è una mappa che traccia la quantità di segnalazioni ricevute per ciascuno validatore
- **news** è la lista di oggetti News da validare

L'oggetto News, rappresenta l'item da validare ed è una struct composta da:

	address source
	string title
	uint expireData
	address[] validators
	uint256 validationsRequired
	bool valid

dove:

- **source** è l'indirizzo della notizia.
- **title** è il titolo della notizia. 
- **expireData** è la data di scadenza entro il quale può essere validata. 
- **validationsRequired** è la quantità di validazioni necessarie affinchè la News cambi stato valid a true.
- **validators** rappresenta la lista dei validatori
- **valid** rappresenta lo stato della news (validata/non validata)

<br></br>
 <font size="4">**Sommario delle principali funzioni esposte:**</font>

- **constructor** : costruttore del contratto. Al deploy viene riempito il bilancio del contratto e calcolati i premi e i prezzi di ingresso come validatori. Il msg.sender viene utilizzato per aggiornare la variabile owner e l'array dei validator, facendo del proprietario il primo dei validatori.

- **receive**: permette all'owner di aggiungere ETH al bilancio del contratto con una semplice transazione.

- **addNews**: permette a qualunque utente di inserire una notizia pagando il solo costo della scrittura su blockchain. Per aggiungere una notizia sarà necessario passare alla funzione l'address della notizia, il titolo, il numero di giorni dal momento dell'inserimento entro cui la notizia può essere validata, e il numero di validazioni richieste.

- **addValidator** : permette di iscrivere un utente alla lista di validators al costo in wei indicato da currentPrice. Ricalcolo di currentReward, currentPrice e currentReportsRequired sulla base del nuovo numero di validatori.

- **reportValidator**: permette a qualunque utente validatore di segnalare un altro utente validatore. Il numero di segnalazioni ricevute per validatore è salvato nella mappa validatorReports. Quando il numero di segnalazioni ricevute eguaglia currentReportsRequire l'utente validatore viene rimosso dalla lista dei validatori. 
Nota: quando un utente validatore viene rimosso dalla lista dei validatori, vengono rimosse anche tutte le sue validazioni dalle notizie non valide. (vedi *f. removeValidator*)

- **validateNews**: permette ad un validatore di aggiungersi alla lista dei validators di una specifica News. Ad ogni nuovo validatore il contratto farà un check con il valore validationRequired della notizia sotto processo di validazione. Se il check viene superato il contratto invia ad ogni validatore coinvolto un valore in wei corrispondente a currentReward.
Vengono aggiornate la mappa validatorRewards e la variabile totalRewards.
(vedi *f. rewardValidator*)


NewsManager utilizza la libreria NewsUtils per gli array di address, in particolare per gli array di validatori. NewsUtils contiene 3 funzioni: 

- **count**: restituisce la quantità di validatori nell'array validators
- **findValidatory**: verifica se l'indirizzo in input appartiene alla lista dei validatori.
- **checkValidation**: verifica se la quantità di validatori presenti in una specifica News è uguale o maggiore al numero (di validazioni richieste per quella specifica News) passato in input.

Il valore della singola ricompensa è calcolato come 

	currentReward = bilancio / ( n° di validatori * 5000 )

Il prezzo di iscrizione alla lista dei validatori è calcolato come

	currentPrice = currentReward * 10

A parità di numero di validatori complessivi presenti e bilancio del contratto, ogni validatore recupera il suo investimento iniziale dopo 10 notizie validate.

I voti richiesti per il ban di un validatore rappresenta i 2/3 dei validatori totali

	currentReportsRequired = ( 2 * n° di validatori ) / 3

<br></br>
 <font size="4">**Casi d'uso**</font>

Per mostrare i casi d'uso possiamo riferirci alle prime quattordici transazioni effettuate sul contratto, consultabili al seguente indirizzo:

https://sepolia.etherscan.io/address/0xe140384C27f41C0f7dd30713e763e1bD94E90A35

Di seguito gli accounti coinvolti con i relativi ruoli

![image](/Metamask.png)

**VALIDAZIONE** (prime 6 transazioni)

> **Deploy**\
owner 0x28c8F50F67CB8ff0Ee0412e64C64dAdD92E1F01C\
balance 0.5ETH

> **Creazione News**\
source 0x1994E5e31D4b3e4430821F4C53342882cF94ED54\
title Sepolia test\
daysToNow 10\
validationRequired 2

> **Aggiunta Validator**\
address 0x1482445250eDD8c6079b9D960CF5a53B9C8B360E

> **Validazione News (1° validazione)** \
validator Validator\
source 0x1994E5e31D4b3e4430821F4C53342882cF94ED54

> **Aggiunta Validator2**\
address 0xCbdCEeF5D5C592244da1fc10be29889920b3a6c7

> **Validazione News (2° validazione)**\
validator Validator2\
source 0x1994E5e31D4b3e4430821F4C53342882cF94ED54\

La news diventa valida e il contratto invia le ricompense ai validatori coinvolti nella validazione della notizia:

https://sepolia.etherscan.io/address/0xe140384C27f41C0f7dd30713e763e1bD94E90A35#internaltx

Le prime due transazioni (dal basso) sono i pagamenti effettuati verso gli account Validator e Validator2

**RIMOZIONE VALIDATORE** ( dalla 7° alla 13° transazione )
> **Aggiunta BannedValidator**\
address 0x666659059A10dD88c3eAA0e6eFC50D6dBC04e342\
currentReportsRequired = 2 (4 validatori presenti)

> **Creazione News**\
source 0x19944fe9D436C1992d096E48265c9df008c2eb13\
title Sepolia test 2\
dayToNow 10\
validationRequired 2

> **Validazione News**\
validator BannedValidator\
source 0x19944fe9D436C1992d096E48265c9df008c2eb13

> **Segnalazione BannedValidator (1° report)**\
validator Owner > validator BannedValidator

> **Segnazione BannedValidator (2° report)**\
validator Validator > validator BannedValidator\
Il validatore BannedValidator viene rimosso dalla lista dei validatori.\
La News creata in questo esempio, avrà 0 / 2 validazioni necessarie per la sua validazione.

> **Validazione News2 (1° validazione)**\
validator Owner\
source 0x19944fe9D436C1992d096E48265c9df008c2eb13

> **Validazione News2 (2° validazione)**\
validator Validator2\
source 0x19944fe9D436C1992d096E48265c9df008c2eb13\
La News diventa valida e i validatori vengono pagati currentReward calcolato al momento del ban del validatore.

**AGGIUNGERE FONDI AL CONTRATTO**
> **Transazione semplice con value**\
address Owner > 0.5 ETH: la funzione receive trasferisce i fondi ricevuto al bilancio del contratto

Il trasferimento di fondi al contratto è riservato all'owner del contratto mentre la validazione delle notizie e la rimozione dei validatori è riservato agli utenti validatori.


