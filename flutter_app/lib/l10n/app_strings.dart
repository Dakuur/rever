/// Localised strings for REVER chatbot.
///
/// Supported languages: en · es · fr · de · pt · it · nl
/// Add new languages by extending the `_pick` call in each getter.
class AppStrings {
  final String langCode;
  const AppStrings._(this.langCode);

  factory AppStrings.of(String code) {
    switch (code) {
      case 'es':
        return const AppStrings._('es');
      case 'fr':
        return const AppStrings._('fr');
      case 'de':
        return const AppStrings._('de');
      case 'pt':
        return const AppStrings._('pt');
      case 'it':
        return const AppStrings._('it');
      case 'nl':
        return const AppStrings._('nl');
      default:
        return const AppStrings._('en');
    }
  }

  // ── Chat screen ────────────────────────────────────────────────────────────

  String get welcomePrePurchase => _pick(
        en: "Hi! 👋 I'm REVER, your shopping assistant. How can I help you today?\n\nYou can ask me about products, sizes, prices or availability.",
        es: "¡Hola! 👋 Soy REVER, tu asistente de compras. ¿En qué puedo ayudarte hoy?\n\nPuedes preguntarme sobre productos, tallas, precios o disponibilidad.",
        fr: "Bonjour ! 👋 Je suis REVER, votre assistant shopping. Comment puis-je vous aider ?\n\nVous pouvez me poser des questions sur les produits, les tailles, les prix ou la disponibilité.",
        de: "Hallo! 👋 Ich bin REVER, Ihr Einkaufsassistent. Wie kann ich Ihnen helfen?\n\nSie können mich nach Produkten, Größen, Preisen oder Verfügbarkeit fragen.",
        pt: "Olá! 👋 Sou o REVER, o seu assistente de compras. Como posso ajudá-lo?\n\nPode perguntar-me sobre produtos, tamanhos, preços ou disponibilidade.",
        it: "Ciao! 👋 Sono REVER, il tuo assistente shopping. Come posso aiutarti?\n\nPuoi chiedermi di prodotti, taglie, prezzi o disponibilità.",
        nl: "Hallo! 👋 Ik ben REVER, jouw winkelassistent. Hoe kan ik je helpen?\n\nJe kunt me vragen over producten, maten, prijzen of beschikbaarheid.",
      );

  String get noProductsFound => _pick(
        en: "Sorry, I couldn't find any products matching that right now. Feel free to ask me about any specific item!",
        es: "Lo siento, no encontré productos que coincidan con eso ahora mismo. ¡No dudes en preguntarme por un artículo específico!",
        fr: "Désolé, je n'ai trouvé aucun produit correspondant pour le moment. N'hésitez pas à me demander un article spécifique !",
        de: "Entschuldigung, ich konnte gerade keine passenden Produkte finden. Fragen Sie mich gerne nach einem bestimmten Artikel!",
        pt: "Desculpe, não encontrei produtos correspondentes agora. Sinta-se à vontade para perguntar sobre um artigo específico!",
        it: "Spiacente, non ho trovato prodotti corrispondenti al momento. Chiedimi pure di un articolo specifico!",
        nl: "Sorry, ik kon momenteel geen overeenkomende producten vinden. Vraag me gerust naar een specifiek artikel!",
      );

  String get genericError => _pick(
        en: "Sorry, something went wrong. Please try again.",
        es: "Lo siento, algo salió mal. Por favor, inténtalo de nuevo.",
        fr: "Désolé, une erreur s'est produite. Veuillez réessayer.",
        de: "Entschuldigung, etwas ist schiefgelaufen. Bitte versuchen Sie es erneut.",
        pt: "Desculpe, algo correu mal. Por favor, tente novamente.",
        it: "Spiacente, si è verificato un errore. Per favore riprova.",
        nl: "Sorry, er is iets misgegaan. Probeer het opnieuw.",
      );

  String get foundDeal => _pick(
        en: "I found a great deal for you! 🎉",
        es: "¡Encontré una gran oferta para ti! 🎉",
        fr: "J'ai trouvé une super offre pour vous ! 🎉",
        de: "Ich habe ein tolles Angebot für Sie gefunden! 🎉",
        pt: "Encontrei uma ótima oferta para si! 🎉",
        it: "Ho trovato una grande offerta per te! 🎉",
        nl: "Ik heb een geweldige aanbieding voor je gevonden! 🎉",
      );

  String get topPickIntro => _pick(
        en: "Here's one of our top picks for you:",
        es: "Aquí tienes una de nuestras mejores selecciones:",
        fr: "Voici l'un de nos meilleurs choix pour vous :",
        de: "Hier ist eine unserer besten Empfehlungen für Sie:",
        pt: "Aqui está uma das nossas melhores escolhas para si:",
        it: "Ecco uno dei nostri migliori prodotti per te:",
        nl: "Hier is een van onze beste keuzes voor jou:",
      );

  String get addToCartIntro => _pick(
        en: "Here's the product I recommended — confirm to add it to your cart:",
        es: "Aquí está el producto que te recomendé — confirma para añadirlo a tu carrito:",
        fr: "Voici le produit que je vous ai recommandé — confirmez pour l'ajouter à votre panier :",
        de: "Hier ist das Produkt, das ich empfohlen habe — bestätigen Sie, um es zum Warenkorb hinzuzufügen:",
        pt: "Aqui está o produto que recomendei — confirme para o adicionar ao carrinho:",
        it: "Ecco il prodotto che ho consigliato — conferma per aggiungerlo al carrello:",
        nl: "Dit is het product dat ik aanbeval — bevestig om het aan je winkelwagen toe te voegen:",
      );

  String get returnRedirectMessage => _pick(
        en: "Sure! Let me take you to our returns & exchanges assistant.",
        es: "¡Claro! Te llevo al asistente de devoluciones y cambios.",
        fr: "Bien sûr ! Je vous amène à notre assistant retours & échanges.",
        de: "Natürlich! Ich bringe Sie zu unserem Rückgabe- und Umtausch-Assistenten.",
        pt: "Claro! Vou levá-lo ao nosso assistente de devoluções e trocas.",
        it: "Certo! Ti porto al nostro assistente per resi e cambi.",
        nl: "Natuurlijk! Ik breng u naar onze retouren & ruilen assistent.",
      );

  String get bannerText => _pick(
        en: "Already purchased? Start a return or exchange.",
        es: "¿Ya compraste? Inicia una devolución o cambio.",
        fr: "Déjà acheté ? Commencez un retour ou un échange.",
        de: "Bereits gekauft? Starten Sie eine Rückgabe oder einen Umtausch.",
        pt: "Já comprou? Inicie uma devolução ou troca.",
        it: "Hai già acquistato? Avvia un reso o un cambio.",
        nl: "Al gekocht? Start een retour of ruil.",
      );

  String get bannerCta => _pick(
        en: "Start →",
        es: "Empezar →",
        fr: "Commencer →",
        de: "Starten →",
        pt: "Começar →",
        it: "Inizia →",
        nl: "Starten →",
      );

  String get navReturns => _pick(
        en: "Returns",
        es: "Devoluciones",
        fr: "Retours",
        de: "Rückgaben",
        pt: "Devoluções",
        it: "Resi",
        nl: "Retouren",
      );

  String get inputPlaceholder => _pick(
        en: "Ask about products…",
        es: "Pregunta sobre productos…",
        fr: "Posez une question sur les produits…",
        de: "Fragen Sie nach Produkten…",
        pt: "Pergunte sobre produtos…",
        it: "Chiedi dei prodotti…",
        nl: "Stel een vraag over producten…",
      );

  String get loadingText => _pick(
        en: "Loading…",
        es: "Cargando…",
        fr: "Chargement…",
        de: "Laden…",
        pt: "A carregar…",
        it: "Caricamento…",
        nl: "Laden…",
      );

  String get resetDialogTitle => _pick(
        en: "Start a new chat?",
        es: "¿Iniciar una nueva conversación?",
        fr: "Démarrer une nouvelle conversation ?",
        de: "Neuen Chat starten?",
        pt: "Iniciar uma nova conversa?",
        it: "Iniziare una nuova chat?",
        nl: "Nieuwe chat starten?",
      );

  String get resetDialogSubtitle => _pick(
        en: "This will clear the current conversation.",
        es: "Esto borrará la conversación actual.",
        fr: "Cela effacera la conversation en cours.",
        de: "Dadurch wird das aktuelle Gespräch gelöscht.",
        pt: "Isso irá limpar a conversa atual.",
        it: "Questo cancellerà la conversazione corrente.",
        nl: "Dit verwijdert het huidige gesprek.",
      );

  String get resetDialogCancel => _pick(
        en: "Cancel",
        es: "Cancelar",
        fr: "Annuler",
        de: "Abbrechen",
        pt: "Cancelar",
        it: "Annulla",
        nl: "Annuleren",
      );

  String get resetDialogConfirm => _pick(
        en: "Clear",
        es: "Borrar",
        fr: "Effacer",
        de: "Löschen",
        pt: "Limpar",
        it: "Cancella",
        nl: "Wissen",
      );

  // ── Return flow screen ─────────────────────────────────────────────────────

  String get returnNavTitle => _pick(
        en: "Returns & Exchanges",
        es: "Devoluciones y Cambios",
        fr: "Retours & Échanges",
        de: "Rückgaben & Umtausch",
        pt: "Devoluções e Trocas",
        it: "Resi e Cambi",
        nl: "Retouren & Ruilen",
      );

  String get returnInitMessage => _pick(
        en: "Hi! I'm here to help with your return. 📦\n\n"
            "Please share the following in one message:\n"
            "• Your **email address**\n"
            "• Your **order number** (e.g. #1001)\n"
            "• The **product** you'd like to return\n\n"
            "Example: *jane@example.com, #1001, blue snowboard*",
        es: "¡Hola! Estoy aquí para ayudarte con tu devolución. 📦\n\n"
            "Por favor, envía lo siguiente en un mensaje:\n"
            "• Tu **correo electrónico**\n"
            "• Tu **número de pedido** (ej. #1001)\n"
            "• El **producto** que deseas devolver\n\n"
            "Ejemplo: *jane@example.com, #1001, tabla azul de snowboard*",
        fr: "Bonjour ! Je suis là pour vous aider avec votre retour. 📦\n\n"
            "Veuillez partager les informations suivantes en un seul message :\n"
            "• Votre **adresse e-mail**\n"
            "• Votre **numéro de commande** (ex. #1001)\n"
            "• Le **produit** que vous souhaitez retourner\n\n"
            "Exemple : *jane@example.com, #1001, snowboard bleu*",
        de: "Hallo! Ich bin hier, um Ihnen bei Ihrer Rückgabe zu helfen. 📦\n\n"
            "Bitte teilen Sie folgendes in einer Nachricht mit:\n"
            "• Ihre **E-Mail-Adresse**\n"
            "• Ihre **Bestellnummer** (z.B. #1001)\n"
            "• Das **Produkt**, das Sie zurückgeben möchten\n\n"
            "Beispiel: *jane@example.com, #1001, blaues Snowboard*",
        pt: "Olá! Estou aqui para ajudá-lo com a sua devolução. 📦\n\n"
            "Por favor, partilhe o seguinte numa só mensagem:\n"
            "• O seu **endereço de e-mail**\n"
            "• O seu **número de pedido** (ex. #1001)\n"
            "• O **produto** que deseja devolver\n\n"
            "Exemplo: *jane@example.com, #1001, snowboard azul*",
        it: "Ciao! Sono qui per aiutarti con il tuo reso. 📦\n\n"
            "Invia le seguenti informazioni in un solo messaggio:\n"
            "• Il tuo **indirizzo e-mail**\n"
            "• Il tuo **numero d'ordine** (es. #1001)\n"
            "• Il **prodotto** che desideri restituire\n\n"
            "Esempio: *jane@example.com, #1001, snowboard blu*",
        nl: "Hallo! Ik ben hier om je te helpen met je retour. 📦\n\n"
            "Stuur het volgende in één bericht:\n"
            "• Je **e-mailadres**\n"
            "• Je **bestelnummer** (bijv. #1001)\n"
            "• Het **product** dat je wilt retourneren\n\n"
            "Voorbeeld: *jane@example.com, #1001, blauwe snowboard*",
      );

  String get orderNumberInvalidError => _pick(
        en: "That order number doesn't appear to be valid. Please double-check and try again.",
        es: "Ese número de pedido no parece válido. Por favor, verifícalo e inténtalo de nuevo.",
        fr: "Ce numéro de commande ne semble pas valide. Veuillez vérifier et réessayer.",
        de: "Diese Bestellnummer scheint nicht gültig zu sein. Bitte überprüfen Sie sie und versuchen Sie es erneut.",
        pt: "Esse número de pedido não parece válido. Por favor, verifique e tente novamente.",
        it: "Questo numero d'ordine non sembra valido. Per favore, verificalo e riprova.",
        nl: "Dat bestelnummer lijkt niet geldig te zijn. Controleer het en probeer het opnieuw.",
      );

  String get missingInfoError => _pick(
        en: "I need your **email**, **order number**, and **product name**.\n\n"
            "Example: *jane@example.com, #1001, blue snowboard*",
        es: "Necesito tu **correo electrónico**, **número de pedido** y **nombre del producto**.\n\n"
            "Ejemplo: *jane@example.com, #1001, tabla azul de snowboard*",
        fr: "J'ai besoin de votre **adresse e-mail**, **numéro de commande** et **nom du produit**.\n\n"
            "Exemple : *jane@example.com, #1001, snowboard bleu*",
        de: "Ich benötige Ihre **E-Mail-Adresse**, **Bestellnummer** und **Produktname**.\n\n"
            "Beispiel: *jane@example.com, #1001, blaues Snowboard*",
        pt: "Preciso do seu **e-mail**, **número de pedido** e **nome do produto**.\n\n"
            "Exemplo: *jane@example.com, #1001, snowboard azul*",
        it: "Ho bisogno della tua **e-mail**, **numero d'ordine** e **nome del prodotto**.\n\n"
            "Esempio: *jane@example.com, #1001, snowboard blu*",
        nl: "Ik heb je **e-mailadres**, **bestelnummer** en **productnaam** nodig.\n\n"
            "Voorbeeld: *jane@example.com, #1001, blauwe snowboard*",
      );

  String get productQueryPrompt => _pick(
        en: "Got it! Which product would you like to return? Please describe it briefly.",
        es: "¡Entendido! ¿Qué producto deseas devolver? Por favor, descríbelo brevemente.",
        fr: "Compris ! Quel produit souhaitez-vous retourner ? Décrivez-le brièvement.",
        de: "Verstanden! Welches Produkt möchten Sie zurückgeben? Bitte beschreiben Sie es kurz.",
        pt: "Compreendido! Qual produto deseja devolver? Descreva-o brevemente.",
        it: "Capito! Quale prodotto vuoi restituire? Descrivilo brevemente.",
        nl: "Begrepen! Welk product wil je retourneren? Beschrijf het kort.",
      );

  String productNotFoundError(String productQuery) => _pick(
        en: "I couldn't find **\"$productQuery\"** in our catalog. "
            "Could you describe the product differently? "
            "(e.g. use the product name as it appears on your order confirmation)",
        es: "No encontré **\"$productQuery\"** en nuestro catálogo. "
            "¿Podrías describirlo de otra manera? "
            "(p. ej., usa el nombre exacto que aparece en la confirmación de tu pedido)",
        fr: "Je n'ai pas trouvé **\"$productQuery\"** dans notre catalogue. "
            "Pourriez-vous décrire le produit différemment ? "
            "(utilisez le nom du produit tel qu'il apparaît sur votre confirmation de commande)",
        de: "Ich konnte **\"$productQuery\"** nicht in unserem Katalog finden. "
            "Könnten Sie das Produkt anders beschreiben? "
            "(z.B. den Produktnamen wie er auf der Bestellbestätigung steht)",
        pt: "Não encontrei **\"$productQuery\"** no nosso catálogo. "
            "Poderia descrever o produto de outra forma? "
            "(use o nome do produto como aparece na confirmação do pedido)",
        it: "Non ho trovato **\"$productQuery\"** nel nostro catalogo. "
            "Potresti descrivere il prodotto diversamente? "
            "(usa il nome del prodotto come appare nella conferma d'ordine)",
        nl: "Ik kon **\"$productQuery\"** niet vinden in onze catalogus. "
            "Kunt u het product anders beschrijven? "
            "(gebruik de productnaam zoals die op uw orderbevestiging staat)",
      );

  String orderFoundMessage({
    required String orderId,
    required String productTitle,
    required String productVariant,
    required String formattedTotal,
  }) =>
      _pick(
        en: "I found your order! 👍\n\n"
            "**Order #$orderId** — $productTitle ($productVariant)\n"
            "Order total: $formattedTotal\n\n"
            "Could you tell me why you'd like to return this item?",
        es: "¡Encontré tu pedido! 👍\n\n"
            "**Pedido #$orderId** — $productTitle ($productVariant)\n"
            "Total del pedido: $formattedTotal\n\n"
            "¿Podrías contarme por qué deseas devolver este artículo?",
        fr: "J'ai trouvé votre commande ! 👍\n\n"
            "**Commande #$orderId** — $productTitle ($productVariant)\n"
            "Total de la commande : $formattedTotal\n\n"
            "Pourriez-vous me dire pourquoi vous souhaitez retourner cet article ?",
        de: "Ich habe Ihre Bestellung gefunden! 👍\n\n"
            "**Bestellung #$orderId** — $productTitle ($productVariant)\n"
            "Bestellbetrag: $formattedTotal\n\n"
            "Könnten Sie mir sagen, warum Sie diesen Artikel zurückgeben möchten?",
        pt: "Encontrei o seu pedido! 👍\n\n"
            "**Pedido #$orderId** — $productTitle ($productVariant)\n"
            "Total do pedido: $formattedTotal\n\n"
            "Pode dizer-me por que motivo deseja devolver este artigo?",
        it: "Ho trovato il tuo ordine! 👍\n\n"
            "**Ordine #$orderId** — $productTitle ($productVariant)\n"
            "Totale ordine: $formattedTotal\n\n"
            "Puoi dirmi perché vorresti restituire questo articolo?",
        nl: "Ik heb je bestelling gevonden! 👍\n\n"
            "**Bestelling #$orderId** — $productTitle ($productVariant)\n"
            "Besteltotaal: $formattedTotal\n\n"
            "Kunt u me vertellen waarom u dit artikel wilt retourneren?",
      );

  String get aiFallbackEmpathy => _pick(
        en: "I understand, and I'm sorry to hear that. Let me find the best solution for you.",
        es: "Entiendo, y lo siento mucho. Déjame encontrar la mejor solución para ti.",
        fr: "Je comprends, et je suis désolé d'apprendre cela. Laissez-moi trouver la meilleure solution pour vous.",
        de: "Ich verstehe, und es tut mir leid das zu hören. Lassen Sie mich die beste Lösung für Sie finden.",
        pt: "Compreendo, e lamento ouvir isso. Deixe-me encontrar a melhor solução para si.",
        it: "Capisco, e mi dispiace. Lasciami trovare la soluzione migliore per te.",
        nl: "Ik begrijp het, en het spijt me dat te horen. Laat me de beste oplossing voor je vinden.",
      );

  String get ladderIntro => _pick(
        en: "Here's what we can do for you — let's start with the best option:",
        es: "Esto es lo que podemos hacer por ti — empecemos con la mejor opción:",
        fr: "Voici ce que nous pouvons faire pour vous — commençons par la meilleure option :",
        de: "Das können wir für Sie tun — fangen wir mit der besten Option an:",
        pt: "Aqui está o que podemos fazer por si — vamos começar com a melhor opção:",
        it: "Ecco cosa possiamo fare per te — iniziamo con l'opzione migliore:",
        nl: "Dit is wat we voor je kunnen doen — laten we beginnen met de beste optie:",
      );

  String get exchangeDeclinedMessage => _pick(
        en: "No problem! Here's an even better alternative — you'd actually come out ahead with this one:",
        es: "¡Sin problema! Aquí hay una alternativa aún mejor — de hecho, saldrías ganando con esta:",
        fr: "Pas de problème ! Voici une alternative encore meilleure — vous y gagneriez vraiment :",
        de: "Kein Problem! Hier ist eine noch bessere Alternative — dabei würden Sie sogar profitieren:",
        pt: "Sem problema! Aqui está uma alternativa ainda melhor — com esta ficaria a ganhar:",
        it: "Nessun problema! Ecco un'alternativa ancora migliore — con questa ci guadagneresti davvero:",
        nl: "Geen probleem! Hier is een nog betere alternatief — hiermee kom je er zelfs beter van af:",
      );

  String get giftCardDeclinedMessage => _pick(
        en: "Understood. Here's the refund option:",
        es: "Entendido. Aquí está la opción de reembolso:",
        fr: "Compris. Voici l'option de remboursement :",
        de: "Verstanden. Hier ist die Rückerstattungsoption:",
        pt: "Compreendido. Aqui está a opção de reembolso:",
        it: "Capito. Ecco l'opzione di rimborso:",
        nl: "Begrepen. Hier is de terugbetalingsoptie:",
      );

  String confirmationExchange(String email, String shortRef) => _pick(
        en: "Your exchange request is confirmed! ✅\n\n"
            "Our team will contact you at **$email** within 24h "
            "to arrange the new size or colour.\n\n"
            "Reference: **$shortRef**",
        es: "¡Tu solicitud de cambio está confirmada! ✅\n\n"
            "Nuestro equipo se pondrá en contacto contigo en **$email** en 24h "
            "para gestionar la nueva talla o color.\n\n"
            "Referencia: **$shortRef**",
        fr: "Votre demande d'échange est confirmée ! ✅\n\n"
            "Notre équipe vous contactera à **$email** dans les 24h "
            "pour organiser la nouvelle taille ou couleur.\n\n"
            "Référence : **$shortRef**",
        de: "Ihre Umtauschanfrage ist bestätigt! ✅\n\n"
            "Unser Team wird Sie innerhalb von 24h unter **$email** kontaktieren, "
            "um die neue Größe oder Farbe zu arrangieren.\n\n"
            "Referenz: **$shortRef**",
        pt: "O seu pedido de troca está confirmado! ✅\n\n"
            "A nossa equipa entrará em contacto com **$email** em 24h "
            "para tratar do novo tamanho ou cor.\n\n"
            "Referência: **$shortRef**",
        it: "La tua richiesta di cambio è confermata! ✅\n\n"
            "Il nostro team ti contatterà all'indirizzo **$email** entro 24h "
            "per gestire la nuova taglia o colore.\n\n"
            "Riferimento: **$shortRef**",
        nl: "Uw ruilverzoek is bevestigd! ✅\n\n"
            "Ons team neemt binnen 24u contact op via **$email** "
            "om de nieuwe maat of kleur te regelen.\n\n"
            "Referentie: **$shortRef**",
      );

  String confirmationGiftCard(
          String giftCardAmount, String email, String shortRef) =>
      _pick(
        en: "Your store credit is on its way! 🎁\n\n"
            "**$giftCardAmount** will be sent to **$email** within 24h.\n\n"
            "Reference: **$shortRef**",
        es: "¡Tu crédito en tienda está en camino! 🎁\n\n"
            "**$giftCardAmount** será enviado a **$email** en 24h.\n\n"
            "Referencia: **$shortRef**",
        fr: "Votre crédit en magasin est en route ! 🎁\n\n"
            "**$giftCardAmount** sera envoyé à **$email** dans les 24h.\n\n"
            "Référence : **$shortRef**",
        de: "Ihr Guthaben ist auf dem Weg! 🎁\n\n"
            "**$giftCardAmount** wird innerhalb von 24h an **$email** gesendet.\n\n"
            "Referenz: **$shortRef**",
        pt: "O seu crédito de loja está a caminho! 🎁\n\n"
            "**$giftCardAmount** será enviado para **$email** em 24h.\n\n"
            "Referência: **$shortRef**",
        it: "Il tuo credito in negozio è in arrivo! 🎁\n\n"
            "**$giftCardAmount** verrà inviato a **$email** entro 24h.\n\n"
            "Riferimento: **$shortRef**",
        nl: "Uw winkelkrediet is onderweg! 🎁\n\n"
            "**$giftCardAmount** wordt binnen 24u naar **$email** gestuurd.\n\n"
            "Referentie: **$shortRef**",
      );

  String confirmationRefund(String total, String shortRef) => _pick(
        en: "Refund submitted. 💳\n\n"
            "**$total** will be returned to your original payment method in 3–5 business days.\n\n"
            "Reference: **$shortRef**",
        es: "Reembolso enviado. 💳\n\n"
            "**$total** será devuelto a tu método de pago original en 3–5 días hábiles.\n\n"
            "Referencia: **$shortRef**",
        fr: "Remboursement soumis. 💳\n\n"
            "**$total** sera restitué à votre moyen de paiement d'origine sous 3 à 5 jours ouvrés.\n\n"
            "Référence : **$shortRef**",
        de: "Rückerstattung eingereicht. 💳\n\n"
            "**$total** wird innerhalb von 3–5 Werktagen auf Ihr ursprüngliches Zahlungsmittel zurückgebucht.\n\n"
            "Referenz: **$shortRef**",
        pt: "Reembolso submetido. 💳\n\n"
            "**$total** será devolvido ao seu método de pagamento original em 3 a 5 dias úteis.\n\n"
            "Referência: **$shortRef**",
        it: "Rimborso inviato. 💳\n\n"
            "**$total** sarà restituito al tuo metodo di pagamento originale in 3–5 giorni lavorativi.\n\n"
            "Riferimento: **$shortRef**",
        nl: "Terugbetaling ingediend. 💳\n\n"
            "**$total** wordt binnen 3–5 werkdagen teruggestort op uw oorspronkelijke betaalmethode.\n\n"
            "Referentie: **$shortRef**",
      );

  String get confirmationDefault => _pick(
        en: "Your request has been submitted.",
        es: "Tu solicitud ha sido enviada.",
        fr: "Votre demande a été soumise.",
        de: "Ihre Anfrage wurde eingereicht.",
        pt: "O seu pedido foi enviado.",
        it: "La tua richiesta è stata inviata.",
        nl: "Uw verzoek is ingediend.",
      );

  // ── Return flow input placeholders ────────────────────────────────────────

  String get returnPlaceholderInfo => _pick(
        en: "Email, order number & product…",
        es: "Correo, número de pedido y producto…",
        fr: "E-mail, numéro de commande et produit…",
        de: "E-Mail, Bestellnummer und Produkt…",
        pt: "E-mail, número de pedido e produto…",
        it: "E-mail, numero d'ordine e prodotto…",
        nl: "E-mail, bestelnummer en product…",
      );

  String get returnPlaceholderProduct => _pick(
        en: "Product name…",
        es: "Nombre del producto…",
        fr: "Nom du produit…",
        de: "Produktname…",
        pt: "Nome do produto…",
        it: "Nome del prodotto…",
        nl: "Productnaam…",
      );

  String get returnPlaceholderReason => _pick(
        en: "Describe the reason…",
        es: "Describe el motivo…",
        fr: "Décrivez la raison…",
        de: "Beschreiben Sie den Grund…",
        pt: "Descreva o motivo…",
        it: "Descrivi il motivo…",
        nl: "Beschrijf de reden…",
      );

  // ── Incentive step card ────────────────────────────────────────────────────

  String get exchangeTitle => _pick(
        en: "Size or Colour Exchange",
        es: "Cambio de talla o color",
        fr: "Échange de taille ou de couleur",
        de: "Größen- oder Farb-Tausch",
        pt: "Troca de tamanho ou cor",
        it: "Cambio taglia o colore",
        nl: "Ruilen van maat of kleur",
      );

  String get exchangeSubtitle => _pick(
        en: "Free, instant — no questions asked",
        es: "Gratis, inmediato — sin preguntas",
        fr: "Gratuit, instantané — sans question",
        de: "Kostenlos, sofort — keine Fragen",
        pt: "Gratuito, imediato — sem perguntas",
        it: "Gratuito, istantaneo — nessuna domanda",
        nl: "Gratis, direct — geen vragen",
      );

  String exchangeBody(String productTitle, String productVariant) => _pick(
        en: "We'll swap your $productTitle ($productVariant) for any other available size or colour.",
        es: "Cambiaremos tu $productTitle ($productVariant) por cualquier otra talla o color disponible.",
        fr: "Nous échangerons votre $productTitle ($productVariant) contre toute autre taille ou couleur disponible.",
        de: "Wir tauschen Ihr $productTitle ($productVariant) gegen eine andere verfügbare Größe oder Farbe.",
        pt: "Trocamos o seu $productTitle ($productVariant) por qualquer outro tamanho ou cor disponível.",
        it: "Sostituiremo il tuo $productTitle ($productVariant) con qualsiasi altra taglia o colore disponibile.",
        nl: "We ruilen uw $productTitle ($productVariant) voor elke andere beschikbare maat of kleur.",
      );

  String get exchangeAcceptLabel => _pick(
        en: "Accept Exchange",
        es: "Aceptar el cambio",
        fr: "Accepter l'échange",
        de: "Tausch akzeptieren",
        pt: "Aceitar a troca",
        it: "Accetta il cambio",
        nl: "Ruil accepteren",
      );

  String get exchangeDeclineLabel => _pick(
        en: "I'd prefer something else",
        es: "Prefiero otra opción",
        fr: "Je préfère autre chose",
        de: "Ich hätte lieber etwas anderes",
        pt: "Prefiro outra opção",
        it: "Preferirei qualcos'altro",
        nl: "Ik wil liever iets anders",
      );

  String get exchangeConfirmedText => _pick(
        en: "Exchange requested! ✓",
        es: "¡Cambio solicitado! ✓",
        fr: "Échange demandé ! ✓",
        de: "Tausch angefordert! ✓",
        pt: "Troca solicitada! ✓",
        it: "Cambio richiesto! ✓",
        nl: "Ruil aangevraagd! ✓",
      );

  String get giftCardTitle => _pick(
        en: "Store Credit + 10% Bonus",
        es: "Crédito en tienda + 10% extra",
        fr: "Crédit boutique + 10% bonus",
        de: "Guthaben + 10% Bonus",
        pt: "Crédito na loja + 10% bónus",
        it: "Credito in negozio + 10% bonus",
        nl: "Winkelkrediet + 10% bonus",
      );

  String get giftCardSubtitle => _pick(
        en: "Worth more than a standard refund",
        es: "Vale más que un reembolso estándar",
        fr: "Vaut plus qu'un remboursement standard",
        de: "Mehr wert als eine Standard-Rückerstattung",
        pt: "Vale mais do que um reembolso padrão",
        it: "Vale più di un rimborso standard",
        nl: "Meer waard dan een standaard terugbetaling",
      );

  String giftCardBody({
    required String formattedTotal,
    required String formattedGiftCard,
    required String extraAmount,
    required String currency,
  }) =>
      _pick(
        en: "Instead of $formattedTotal back to your card, get $formattedGiftCard in store credit — that's $extraAmount $currency extra.",
        es: "En lugar de $formattedTotal de vuelta a tu tarjeta, obtén $formattedGiftCard en crédito de tienda — son $extraAmount $currency adicionales.",
        fr: "Plutôt que $formattedTotal remboursés sur votre carte, obtenez $formattedGiftCard en crédit boutique — soit $extraAmount $currency de plus.",
        de: "Statt $formattedTotal zurück auf Ihre Karte erhalten Sie $formattedGiftCard als Guthaben — das sind $extraAmount $currency mehr.",
        pt: "Em vez de $formattedTotal devolvidos ao seu cartão, receba $formattedGiftCard em crédito de loja — são $extraAmount $currency a mais.",
        it: "Invece di $formattedTotal restituiti sulla tua carta, ottieni $formattedGiftCard come credito in negozio — $extraAmount $currency in più.",
        nl: "In plaats van $formattedTotal terug op uw kaart, ontvang $formattedGiftCard aan winkelkrediet — dat is $extraAmount $currency extra.",
      );

  String get giftCardAcceptLabel => _pick(
        en: "Accept Store Credit",
        es: "Aceptar crédito en tienda",
        fr: "Accepter le crédit boutique",
        de: "Guthaben akzeptieren",
        pt: "Aceitar crédito na loja",
        it: "Accetta il credito in negozio",
        nl: "Winkelkrediet accepteren",
      );

  String get giftCardDeclineLabel => _pick(
        en: "I want a cash refund",
        es: "Quiero un reembolso en efectivo",
        fr: "Je veux un remboursement en espèces",
        de: "Ich möchte eine Barrückerstattung",
        pt: "Quero um reembolso em dinheiro",
        it: "Voglio un rimborso in contanti",
        nl: "Ik wil een geldterugbetaling",
      );

  String get giftCardConfirmedText => _pick(
        en: "Store credit on its way! ✓",
        es: "¡Crédito en tienda en camino! ✓",
        fr: "Crédit boutique en route ! ✓",
        de: "Guthaben ist unterwegs! ✓",
        pt: "Crédito de loja a caminho! ✓",
        it: "Credito in negozio in arrivo! ✓",
        nl: "Winkelkrediet is onderweg! ✓",
      );

  String get upsellTitle => _pick(
        en: "Try Something New",
        es: "Prueba algo nuevo",
        fr: "Essayez autre chose",
        de: "Probieren Sie etwas Neues",
        pt: "Experimente algo novo",
        it: "Prova qualcosa di nuovo",
        nl: "Probeer iets nieuws",
      );

  String get upsellSubtitle => _pick(
        en: "Apply your return credit toward a better fit",
        es: "Usa tu crédito de devolución para algo mejor",
        fr: "Utilisez votre crédit de retour pour un meilleur choix",
        de: "Verwenden Sie Ihr Rückgabeguthaben für etwas Passenderes",
        pt: "Use o seu crédito de devolução para algo melhor",
        it: "Usa il tuo credito reso per qualcosa di più adatto",
        nl: "Gebruik uw retourkrediet voor een betere keuze",
      );

  String upsellBody(String productTitle) => _pick(
        en: "Not happy with $productTitle? Use your return value to pick any other item from our catalog — same value, no extra cost.",
        es: "¿No estás satisfecho con $productTitle? Usa el valor de tu devolución para elegir otro artículo del catálogo — mismo valor, sin coste adicional.",
        fr: "Pas satisfait de $productTitle ? Utilisez la valeur de votre retour pour choisir un autre article du catalogue — même valeur, sans frais supplémentaires.",
        de: "Nicht zufrieden mit $productTitle? Nutzen Sie den Rückgabewert für einen anderen Artikel aus unserem Katalog — gleicher Wert, keine Extrakosten.",
        pt: "Não está satisfeito com $productTitle? Use o valor da devolução para escolher outro artigo do catálogo — mesmo valor, sem custo extra.",
        it: "Non sei soddisfatto di $productTitle? Usa il valore del reso per scegliere un altro articolo dal catalogo — stesso valore, nessun costo extra.",
        nl: "Niet tevreden met $productTitle? Gebruik de retourwaarde voor een ander artikel uit onze catalogus — zelfde waarde, geen extra kosten.",
      );

  String get upsellAcceptLabel => _pick(
        en: "Browse Alternatives",
        es: "Ver alternativas",
        fr: "Voir les alternatives",
        de: "Alternativen ansehen",
        pt: "Ver alternativas",
        it: "Vedi alternative",
        nl: "Alternatieven bekijken",
      );

  String get upsellDeclineLabel => _pick(
        en: "I'd prefer a refund",
        es: "Prefiero el reembolso",
        fr: "Je préfère un remboursement",
        de: "Ich möchte lieber eine Rückerstattung",
        pt: "Prefiro o reembolso",
        it: "Preferisco il rimborso",
        nl: "Ik wil liever een terugbetaling",
      );

  String get upsellConfirmedText => _pick(
        en: "Great choice! ✓",
        es: "¡Buena elección! ✓",
        fr: "Excellent choix ! ✓",
        de: "Tolle Wahl! ✓",
        pt: "Ótima escolha! ✓",
        it: "Ottima scelta! ✓",
        nl: "Geweldige keuze! ✓",
      );

  String get upsellDeclinedMessage => _pick(
        en: "No problem. Here's the refund option:",
        es: "Sin problema. Aquí está la opción de reembolso:",
        fr: "Pas de problème. Voici l'option de remboursement :",
        de: "Kein Problem. Hier ist die Rückerstattungsoption:",
        pt: "Sem problema. Aqui está a opção de reembolso:",
        it: "Nessun problema. Ecco l'opzione di rimborso:",
        nl: "Geen probleem. Hier is de terugbetalingsoptie:",
      );

  String confirmationUpsell(String email, String shortRef) => _pick(
        en: "Your store credit is reserved! 🛍️\n\n"
            "Browse our catalog and use your credit at checkout. "
            "A confirmation will be sent to **$email**.\n\n"
            "Reference: **$shortRef**",
        es: "¡Tu crédito en tienda está reservado! 🛍️\n\n"
            "Explora nuestro catálogo y usa tu crédito al pagar. "
            "Se enviará una confirmación a **$email**.\n\n"
            "Referencia: **$shortRef**",
        fr: "Votre crédit boutique est réservé ! 🛍️\n\n"
            "Parcourez notre catalogue et utilisez votre crédit à la caisse. "
            "Une confirmation sera envoyée à **$email**.\n\n"
            "Référence : **$shortRef**",
        de: "Ihr Guthaben ist reserviert! 🛍️\n\n"
            "Stöbern Sie in unserem Katalog und nutzen Sie Ihr Guthaben beim Checkout. "
            "Eine Bestätigung wird an **$email** gesendet.\n\n"
            "Referenz: **$shortRef**",
        pt: "O seu crédito de loja está reservado! 🛍️\n\n"
            "Explore o catálogo e use o crédito na finalização da compra. "
            "Uma confirmação será enviada para **$email**.\n\n"
            "Referência: **$shortRef**",
        it: "Il tuo credito in negozio è riservato! 🛍️\n\n"
            "Sfoglia il catalogo e usa il credito al checkout. "
            "Una conferma verrà inviata a **$email**.\n\n"
            "Riferimento: **$shortRef**",
        nl: "Uw winkelkrediet is gereserveerd! 🛍️\n\n"
            "Blader door onze catalogus en gebruik uw krediet bij het afrekenen. "
            "Een bevestiging wordt verzonden naar **$email**.\n\n"
            "Referentie: **$shortRef**",
      );

  String get refundTitle => _pick(
        en: "Refund to Original Payment",
        es: "Reembolso al pago original",
        fr: "Remboursement au paiement d'origine",
        de: "Rückerstattung auf das Original-Zahlungsmittel",
        pt: "Reembolso ao método de pagamento original",
        it: "Rimborso al metodo di pagamento originale",
        nl: "Terugbetaling naar originele betaalmethode",
      );

  String get refundSubtitle => _pick(
        en: "3–5 business days",
        es: "3–5 días hábiles",
        fr: "3 à 5 jours ouvrés",
        de: "3–5 Werktage",
        pt: "3–5 dias úteis",
        it: "3–5 giorni lavorativi",
        nl: "3–5 werkdagen",
      );

  String refundBody(String formattedTotal) => _pick(
        en: "$formattedTotal will be returned to your original payment method.",
        es: "$formattedTotal será devuelto a tu método de pago original.",
        fr: "$formattedTotal sera restitué à votre moyen de paiement d'origine.",
        de: "$formattedTotal wird auf Ihr ursprüngliches Zahlungsmittel zurückgebucht.",
        pt: "$formattedTotal será devolvido ao seu método de pagamento original.",
        it: "$formattedTotal sarà restituito al tuo metodo di pagamento originale.",
        nl: "$formattedTotal wordt teruggestort op uw oorspronkelijke betaalmethode.",
      );

  String get refundAcceptLabel => _pick(
        en: "Confirm Refund",
        es: "Confirmar reembolso",
        fr: "Confirmer le remboursement",
        de: "Rückerstattung bestätigen",
        pt: "Confirmar reembolso",
        it: "Conferma rimborso",
        nl: "Terugbetaling bevestigen",
      );

  String get refundConfirmedText => _pick(
        en: "Refund submitted ✓",
        es: "Reembolso enviado ✓",
        fr: "Remboursement soumis ✓",
        de: "Rückerstattung eingereicht ✓",
        pt: "Reembolso enviado ✓",
        it: "Rimborso inviato ✓",
        nl: "Terugbetaling ingediend ✓",
      );

  String get cardDecliningText => _pick(
        en: "Got it, showing next option…",
        es: "Entendido, mostrando la siguiente opción…",
        fr: "Compris, affichage de l'option suivante…",
        de: "Verstanden, zeige nächste Option…",
        pt: "Compreendido, a mostrar a próxima opção…",
        it: "Capito, mostro l'opzione successiva…",
        nl: "Begrepen, volgende optie wordt weergegeven…",
      );

  // ── Language name (for AI context injection) ──────────────────────────────

  String get languageName => _pick(
        en: "English",
        es: "Spanish",
        fr: "French",
        de: "German",
        pt: "Portuguese",
        it: "Italian",
        nl: "Dutch",
      );

  // ── Internal helper ────────────────────────────────────────────────────────

  String _pick({
    required String en,
    required String es,
    required String fr,
    required String de,
    required String pt,
    required String it,
    required String nl,
  }) {
    switch (langCode) {
      case 'es':
        return es;
      case 'fr':
        return fr;
      case 'de':
        return de;
      case 'pt':
        return pt;
      case 'it':
        return it;
      case 'nl':
        return nl;
      default:
        return en;
    }
  }
}
