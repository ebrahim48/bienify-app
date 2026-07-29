import 'package:get/get.dart';

import '../constants/app_strings.dart';

/// Locale dictionaries backing the En / Spa toggle on the onboarding screen.
///
/// Registered on `GetMaterialApp(translations: AppTranslations(), ...)`; the
/// active locale is driven by `LocalizationController`.
class AppTranslations extends Translations {
  @override
  Map<String, Map<String, String>> get keys => {
    'en_US': _en,
    'es_ES': _es,
  };

  static const Map<String, String> _en = {
    AppStrings.appName: 'Bienify',

    // Location permission
    AppStrings.allowYourLocation: 'Allow your Location',
    AppStrings.deny: 'Deny',
    AppStrings.allow: 'Allow',

    // Onboarding
    AppStrings.onboardingTitle1: 'Find the Right Doctor',
    AppStrings.onboardingBody1:
        'Search by specialty, view profiles, and book appointments',
    AppStrings.onboardingTitle2: 'Consult from Anywhere',
    AppStrings.onboardingBody2: 'Talk to certified doctors',
    AppStrings.onboardingTitle3: 'Get Medicines Delivered',
    AppStrings.onboardingBody3:
        'Order prescription medicines easily and track delivery in real time',

    AppStrings.signInWithGoogle: 'Sign in with Google',
    AppStrings.signInWithApple: 'Sign in with Apple',
    AppStrings.or: 'OR',
    AppStrings.enterPhoneNumber: 'Enter Phone Number',
    AppStrings.continueWithPhoneNumber: 'Continue With Phone Number',
    AppStrings.alreadyHaveAnAccount: 'Already have an account?',
    AppStrings.joinAsADoctor: 'Join as a Doctor',

    // Phone / OTP
    AppStrings.enterPhoneNumberTitle: 'Enter Phone Number',
    AppStrings.getOtp: 'Get OTP',
    AppStrings.enterOtp: 'Enter OTP',
    AppStrings.codeSentHeading: 'Code sent-Check your text messages',
    AppStrings.codeSentSubtitle: 'Enter the code to Conform your number',
    AppStrings.enterSixDigitCode: 'Enter 6 digit Code',
    AppStrings.codeNotReceived: 'Code not received?',
    AppStrings.requestNewOtp: 'Request New OTP',
    AppStrings.resendIn: 'Request New OTP in @seconds s',
    AppStrings.next: 'Next',
    AppStrings.verifyNow: 'Verify Now',

    // Profile setup
    AppStrings.setUpYourProfile: 'Set Up Your Profile',
    AppStrings.name: 'Name',
    AppStrings.nameHint: 'ex.Mustafizur Rahman',
    AppStrings.gender: 'Gender',
    AppStrings.male: 'Male',
    AppStrings.female: 'Female',
    AppStrings.age: 'Age',
    AppStrings.email: 'Email',
    AppStrings.emailHint: 'example@gmail.com',
    AppStrings.password: 'Password',
    AppStrings.passwordHint: 'Enter your Password',
    AppStrings.retypePasswordHint: 'Re-type your password',
    AppStrings.saveAndContinue: 'Save & Continue',

    // Success
    AppStrings.allSetUp: 'You’re all set up !',
    AppStrings.careStartsHere: 'Your care starts here—find a doctor now',
    AppStrings.getStarted: 'Get Started',
    AppStrings.passwordUpdated: 'Password Updated!',
    AppStrings.loginNow: 'Login Now',

    // Login
    AppStrings.login: 'Login',
    AppStrings.forgotYourPassword: 'Forgot your password?',
    AppStrings.resetNow: 'Reset Now',
    AppStrings.areYouNewMember: 'Are you New Member?',
    AppStrings.signUpNow: 'Sign Up Now',

    // Reset password
    AppStrings.enterNewPassword: 'Enter New Password',
    AppStrings.newPasswordHint: 'Enter your New Password',
    AppStrings.retypeNewPasswordHint: 'Re-type  your New Password',
    AppStrings.resetPassword: 'Reset Password',

    // Country picker
    AppStrings.selectCountry: 'Select Country',
    AppStrings.searchCountry: 'Search country or code',

    // Validation
    AppStrings.errorNameRequired: 'Please enter your name',
    AppStrings.errorGenderRequired: 'Please select your gender',
    AppStrings.errorAgeRequired: 'Please select your age range',
    AppStrings.errorEmailRequired: 'Please enter your email',
    AppStrings.errorEmailInvalid: 'Please enter a valid email address',
    AppStrings.errorPasswordRequired: 'Please enter your password',
    AppStrings.errorPasswordTooShort:
        'Password must be at least 8 characters long',
    AppStrings.errorPasswordMismatch: 'Passwords do not match',
    AppStrings.errorPhoneRequired: 'Please enter your phone number',
    AppStrings.errorPhoneInvalid: 'Please enter a valid phone number',
    AppStrings.errorOtpRequired: 'Please enter the code we sent you',
    AppStrings.errorOtpInvalid: 'The code must be 6 digits',

    // Bottom navigation
    AppStrings.navHome: 'Home',
    AppStrings.navAppointments: 'Appointments',
    AppStrings.navDoctors: 'Doctors',
    AppStrings.navPharmacy: 'Pharmacy',

    // Home
    AppStrings.searchSpecialty: 'Search Specialty',
    AppStrings.upcomingAppointments: 'Upcoming Appointments',
    AppStrings.nearbyDoctors: 'Nearby Doctors',
    AppStrings.seeAll: 'See all',
    AppStrings.seeAvailability: 'See availability',
    AppStrings.join: 'Join',
    AppStrings.reviewRequest: 'Review request',
    AppStrings.requestedBy: 'From @doctor',
    AppStrings.statusRequestSent: 'Request sent',
    AppStrings.statusInProgress: 'In progress',
    AppStrings.statusReady: 'Results ready',
    AppStrings.noUpcomingAppointments: 'No upcoming appointments',
    AppStrings.noDoctorsFound: 'No doctors found',
    AppStrings.retry: 'Retry',

    // Search & directory
    AppStrings.search: 'Search',
    AppStrings.filterAll: 'All',

    // Find a doctor
    AppStrings.findADoctorTitle: 'Find a doctor',
    AppStrings.exploreCategories: 'Explore Categories',
    AppStrings.findCategoryDoctors: 'Find @category Doctors',
    AppStrings.categoryDoctorLists: '@category Doctor lists',

    // Doctor filter
    AppStrings.priceRange: 'Price range',
    AppStrings.rating: 'Rating',
    AppStrings.starCount: '@count Star',
    AppStrings.reset: 'Reset',
    AppStrings.apply: 'Apply',

    // Doctor details
    AppStrings.doctorDetails: 'Doctor Details',
    AppStrings.reviewsCount: '(@count reviews)',
    AppStrings.perConsultation: '/Consultation',
    AppStrings.yearsCount: '@count years',
    AppStrings.experience: 'Experience',
    AppStrings.patients: 'patients',
    AppStrings.workingTime: 'Working Time:',
    AppStrings.biography: 'Biography:',
    AppStrings.selectYearAndDate: 'Select Year &Date',
    AppStrings.availableTime: 'Available Time',
    AppStrings.bookAppointment: 'Book Appointment',
    AppStrings.selectTimeSlot: 'Pick a day and a time slot first',

    // Payment
    AppStrings.paymentSummary: 'Payment Summary',
    AppStrings.medicalDocument: 'Medical Document (If any)',
    AppStrings.attachment: 'Attachment',
    AppStrings.camera: 'Camera',
    AppStrings.attachmentAdded: 'Document attached',
    AppStrings.consultationFee: 'Consultation Fee',
    AppStrings.vat: 'VAT',
    AppStrings.totalPayable: 'Total Payable',
    AppStrings.rxWallet: 'RxWallet',
    AppStrings.walletBalance: 'Balance: @amount',
    AppStrings.walletDeduction: '@amount will be deducted from wallet',
    AppStrings.choosePaymentMethod: 'Choose payment method',
    AppStrings.paymentDebitCredit: 'Debit/Credit',
    AppStrings.paymentApplePay: 'Apple/Google Pay',
    AppStrings.paymentBankTransfer: 'Bank Transfer',
    AppStrings.paymentTpago: 'TPAGO',
    AppStrings.paymentPaypal: 'Paypal',
    AppStrings.paymentCash: 'Cash/Pay at Location',
    AppStrings.payAmount: 'Pay @amount',
    AppStrings.appointmentScheduled:
        'Your appointment has been successfully scheduled',
    AppStrings.backToAppointment: 'Back to Appointment',

    // Cash payment process
    AppStrings.howToPaymentWorks: 'How to Payment Works',
    AppStrings.payStep1Title: 'Get your payment code',
    AppStrings.payStep1Body: 'Copy the unique code below',
    AppStrings.payStep2Title: 'Visit a nearby agent or store',
    AppStrings.payStep2Body: 'We’ll help you find one close to you',
    AppStrings.payStep3Title: 'Pay using cash',
    AppStrings.payStep3Body: 'Show your code and pay the exact amount',
    AppStrings.payStep4Title: 'Booking confirmed automatically',
    AppStrings.payStep4Body: 'We receive instant confirmation',

    AppStrings.yourPaymentCode: 'YOUR PAYMENT CODE',
    AppStrings.paymentCode: 'PAYMENT CODE',
    AppStrings.useCodeAtAgent: 'Use this code at any payment agent',
    AppStrings.copyCode: 'Copy Code',
    AppStrings.codeCopied: 'Code copied!',
    AppStrings.codeCopiedDetail: '@code is in your clipboard',
    AppStrings.validForHours: 'Valid for @hours hours',
    AppStrings.codeExpiresAfter: 'Code expires after payment deadline',
    AppStrings.remaining: 'remaining',
    AppStrings.amountToPay: 'Amount to pay',
    AppStrings.findPaymentLocation: 'Find Payment Location',

    AppStrings.nearbyPaymentPoints: 'Nearby Payment Points',
    AppStrings.mapView: 'Map',
    AppStrings.listView: 'List',
    AppStrings.yourLocation: 'Your location',
    AppStrings.allNearby: 'ALL NEARBY',
    AppStrings.directions: 'Directions',
    AppStrings.go: 'Go',
    AppStrings.openNow: 'Open Now',
    AppStrings.openLabel: 'Open',
    AppStrings.closedLabel: 'Closed',
    AppStrings.foundALocation: 'I’ve Found a Location',

    AppStrings.paymentPending: 'Payment Pending',
    AppStrings.waitingForPayment: 'Waiting for Payment',
    AppStrings.waitingForPaymentBody:
        'Complete your payment at a nearby agent using your code below',
    AppStrings.timeRemaining: 'Time remaining',
    AppStrings.codeValidFrom: 'Code valid for @hours hours from generation',
    AppStrings.autoChecking: 'Auto-checking every @seconds seconds',
    AppStrings.checkPaymentStatus: 'Check Payment Status',
    AppStrings.viewNearbyLocations: 'View Nearby Locations',

    AppStrings.paymentConfirmed: 'Payment Confirmed!',
    AppStrings.paymentConfirmedBody:
        'Your booking is now confirmed and your medicines are being prepared.',
    AppStrings.bookingDetails: 'BOOKING DETAILS',
    AppStrings.orderId: 'Order ID',
    AppStrings.date: 'Date',
    AppStrings.estimatedDelivery: 'Estimated Delivery',
    AppStrings.pharmacyLabel: 'Pharmacy',
    AppStrings.prescription: 'Prescription',
    AppStrings.medicinesCount: 'MEDICINES (@count)',
    AppStrings.totalPaid: 'Total Paid',
    AppStrings.paidViaCash: 'Paid via Cash at Agent • Code @code',
    AppStrings.goHome: 'Go Home',

    // Chat
    AppStrings.online: 'Online',
    AppStrings.typeYourMessage: 'Type your message...',

    // Appointments
    AppStrings.myAppointments: 'My Appointments',
    AppStrings.upcoming: 'Upcoming',
    AppStrings.past: 'Past',
    AppStrings.noAppointmentsYet: 'You have no appointments yet',
    AppStrings.findADoctor: 'Find a doctor',
    AppStrings.joinOpensSoon: 'You can join 15 minutes before your slot',

    // Pharmacy
    AppStrings.pharmacyTitle: 'Pharmacy',
    AppStrings.pharmacySubtitle: 'Prescription medicines, delivered',
    AppStrings.addToCart: 'Add',
    AppStrings.addedToCart: 'Added to your cart',
    AppStrings.inStock: 'In stock',
    AppStrings.outOfStock: 'Out of stock',

    // Feedback
    AppStrings.otpResent: 'A new code is on its way',
    AppStrings.somethingWentWrong: 'Something went wrong. Please try again.',
    AppStrings.noInternetConnection: 'No internet connection',
  };

  static const Map<String, String> _es = {
    AppStrings.appName: 'Bienify',

    // Permiso de ubicación
    AppStrings.allowYourLocation: 'Permite tu ubicación',
    AppStrings.deny: 'Denegar',
    AppStrings.allow: 'Permitir',

    // Onboarding
    AppStrings.onboardingTitle1: 'Encuentra al médico ideal',
    AppStrings.onboardingBody1:
        'Busca por especialidad, mira perfiles y reserva citas',
    AppStrings.onboardingTitle2: 'Consulta desde donde estés',
    AppStrings.onboardingBody2: 'Habla con médicos certificados',
    AppStrings.onboardingTitle3: 'Recibe tus medicamentos',
    AppStrings.onboardingBody3:
        'Pide medicamentos con receta y sigue la entrega en tiempo real',

    AppStrings.signInWithGoogle: 'Iniciar sesión con Google',
    AppStrings.signInWithApple: 'Iniciar sesión con Apple',
    AppStrings.or: 'O',
    AppStrings.enterPhoneNumber: 'Ingresa tu número',
    AppStrings.continueWithPhoneNumber: 'Continuar con el número',
    AppStrings.alreadyHaveAnAccount: '¿Ya tienes una cuenta?',
    AppStrings.joinAsADoctor: 'Únete como médico',

    // Teléfono / OTP
    AppStrings.enterPhoneNumberTitle: 'Ingresa tu número',
    AppStrings.getOtp: 'Obtener OTP',
    AppStrings.enterOtp: 'Ingresar OTP',
    AppStrings.codeSentHeading: 'Código enviado: revisa tus mensajes',
    AppStrings.codeSentSubtitle: 'Ingresa el código para confirmar tu número',
    AppStrings.enterSixDigitCode: 'Ingresa el código de 6 dígitos',
    AppStrings.codeNotReceived: '¿No recibiste el código?',
    AppStrings.requestNewOtp: 'Solicitar nuevo OTP',
    AppStrings.resendIn: 'Solicitar nuevo OTP en @seconds s',
    AppStrings.next: 'Siguiente',
    AppStrings.verifyNow: 'Verificar ahora',

    // Perfil
    AppStrings.setUpYourProfile: 'Configura tu perfil',
    AppStrings.name: 'Nombre',
    AppStrings.nameHint: 'ej. Mustafizur Rahman',
    AppStrings.gender: 'Género',
    AppStrings.male: 'Hombre',
    AppStrings.female: 'Mujer',
    AppStrings.age: 'Edad',
    AppStrings.email: 'Correo',
    AppStrings.emailHint: 'ejemplo@gmail.com',
    AppStrings.password: 'Contraseña',
    AppStrings.passwordHint: 'Ingresa tu contraseña',
    AppStrings.retypePasswordHint: 'Repite tu contraseña',
    AppStrings.saveAndContinue: 'Guardar y continuar',

    // Éxito
    AppStrings.allSetUp: '¡Todo listo!',
    AppStrings.careStartsHere:
        'Tu cuidado empieza aquí: encuentra un médico ahora',
    AppStrings.getStarted: 'Comenzar',
    AppStrings.passwordUpdated: '¡Contraseña actualizada!',
    AppStrings.loginNow: 'Iniciar sesión',

    // Login
    AppStrings.login: 'Iniciar sesión',
    AppStrings.forgotYourPassword: '¿Olvidaste tu contraseña?',
    AppStrings.resetNow: 'Restablecer',
    AppStrings.areYouNewMember: '¿Eres nuevo?',
    AppStrings.signUpNow: 'Regístrate',

    // Restablecer contraseña
    AppStrings.enterNewPassword: 'Nueva contraseña',
    AppStrings.newPasswordHint: 'Ingresa tu nueva contraseña',
    AppStrings.retypeNewPasswordHint: 'Repite tu nueva contraseña',
    AppStrings.resetPassword: 'Restablecer contraseña',

    // Selector de país
    AppStrings.selectCountry: 'Selecciona un país',
    AppStrings.searchCountry: 'Busca país o código',

    // Validación
    AppStrings.errorNameRequired: 'Ingresa tu nombre',
    AppStrings.errorGenderRequired: 'Selecciona tu género',
    AppStrings.errorAgeRequired: 'Selecciona tu rango de edad',
    AppStrings.errorEmailRequired: 'Ingresa tu correo',
    AppStrings.errorEmailInvalid: 'Ingresa un correo válido',
    AppStrings.errorPasswordRequired: 'Ingresa tu contraseña',
    AppStrings.errorPasswordTooShort:
        'La contraseña debe tener al menos 8 caracteres',
    AppStrings.errorPasswordMismatch: 'Las contraseñas no coinciden',
    AppStrings.errorPhoneRequired: 'Ingresa tu número de teléfono',
    AppStrings.errorPhoneInvalid: 'Ingresa un número válido',
    AppStrings.errorOtpRequired: 'Ingresa el código que te enviamos',
    AppStrings.errorOtpInvalid: 'El código debe tener 6 dígitos',

    // Navegación inferior
    AppStrings.navHome: 'Inicio',
    AppStrings.navAppointments: 'Citas',
    AppStrings.navDoctors: 'Médicos',
    AppStrings.navPharmacy: 'Farmacia',

    // Inicio
    AppStrings.searchSpecialty: 'Buscar especialidad',
    AppStrings.upcomingAppointments: 'Próximas citas',
    AppStrings.nearbyDoctors: 'Médicos cercanos',
    AppStrings.seeAll: 'Ver todo',
    AppStrings.seeAvailability: 'Ver disponibilidad',
    AppStrings.join: 'Unirse',
    AppStrings.reviewRequest: 'Revisar solicitud',
    AppStrings.requestedBy: 'De @doctor',
    AppStrings.statusRequestSent: 'Solicitud enviada',
    AppStrings.statusInProgress: 'En proceso',
    AppStrings.statusReady: 'Resultados listos',
    AppStrings.noUpcomingAppointments: 'No tienes citas próximas',
    AppStrings.noDoctorsFound: 'No se encontraron médicos',
    AppStrings.retry: 'Reintentar',

    // Búsqueda
    AppStrings.search: 'Buscar',
    AppStrings.filterAll: 'Todos',

    // Buscar un médico
    AppStrings.findADoctorTitle: 'Busca un médico',
    AppStrings.exploreCategories: 'Explorar categorías',
    AppStrings.findCategoryDoctors: 'Buscar médicos de @category',
    AppStrings.categoryDoctorLists: 'Médicos de @category',

    // Filtro
    AppStrings.priceRange: 'Rango de precio',
    AppStrings.rating: 'Valoración',
    AppStrings.starCount: '@count estrellas',
    AppStrings.reset: 'Restablecer',
    AppStrings.apply: 'Aplicar',

    // Detalles del médico
    AppStrings.doctorDetails: 'Detalles del médico',
    AppStrings.reviewsCount: '(@count reseñas)',
    AppStrings.perConsultation: '/Consulta',
    AppStrings.yearsCount: '@count años',
    AppStrings.experience: 'Experiencia',
    AppStrings.patients: 'pacientes',
    AppStrings.workingTime: 'Horario:',
    AppStrings.biography: 'Biografía:',
    AppStrings.selectYearAndDate: 'Selecciona año y fecha',
    AppStrings.availableTime: 'Horas disponibles',
    AppStrings.bookAppointment: 'Reservar cita',
    AppStrings.selectTimeSlot: 'Elige primero un día y una hora',

    // Pago
    AppStrings.paymentSummary: 'Resumen de pago',
    AppStrings.medicalDocument: 'Documento médico (si aplica)',
    AppStrings.attachment: 'Adjunto',
    AppStrings.camera: 'Cámara',
    AppStrings.attachmentAdded: 'Documento adjuntado',
    AppStrings.consultationFee: 'Costo de consulta',
    AppStrings.vat: 'IVA',
    AppStrings.totalPayable: 'Total a pagar',
    AppStrings.rxWallet: 'RxWallet',
    AppStrings.walletBalance: 'Saldo: @amount',
    AppStrings.walletDeduction: 'Se descontarán @amount de la billetera',
    AppStrings.choosePaymentMethod: 'Elige un método de pago',
    AppStrings.paymentDebitCredit: 'Débito/Crédito',
    AppStrings.paymentApplePay: 'Apple/Google Pay',
    AppStrings.paymentBankTransfer: 'Transferencia bancaria',
    AppStrings.paymentTpago: 'TPAGO',
    AppStrings.paymentPaypal: 'Paypal',
    AppStrings.paymentCash: 'Efectivo/Pagar en el lugar',
    AppStrings.payAmount: 'Pagar @amount',
    AppStrings.appointmentScheduled: 'Tu cita se ha agendado correctamente',
    AppStrings.backToAppointment: 'Volver a citas',

    // Pago en efectivo
    AppStrings.howToPaymentWorks: 'Cómo funciona el pago',
    AppStrings.payStep1Title: 'Obtén tu código de pago',
    AppStrings.payStep1Body: 'Copia el código único de abajo',
    AppStrings.payStep2Title: 'Visita un agente o tienda cercana',
    AppStrings.payStep2Body: 'Te ayudamos a encontrar uno cerca de ti',
    AppStrings.payStep3Title: 'Paga en efectivo',
    AppStrings.payStep3Body: 'Muestra tu código y paga el monto exacto',
    AppStrings.payStep4Title: 'Reserva confirmada automáticamente',
    AppStrings.payStep4Body: 'Recibimos la confirmación al instante',

    AppStrings.yourPaymentCode: 'TU CÓDIGO DE PAGO',
    AppStrings.paymentCode: 'CÓDIGO DE PAGO',
    AppStrings.useCodeAtAgent: 'Usa este código en cualquier agente de pago',
    AppStrings.copyCode: 'Copiar código',
    AppStrings.codeCopied: '¡Código copiado!',
    AppStrings.codeCopiedDetail: '@code está en tu portapapeles',
    AppStrings.validForHours: 'Válido por @hours horas',
    AppStrings.codeExpiresAfter: 'El código vence tras la fecha límite',
    AppStrings.remaining: 'restante',
    AppStrings.amountToPay: 'Monto a pagar',
    AppStrings.findPaymentLocation: 'Buscar punto de pago',

    AppStrings.nearbyPaymentPoints: 'Puntos de pago cercanos',
    AppStrings.mapView: 'Mapa',
    AppStrings.listView: 'Lista',
    AppStrings.yourLocation: 'Tu ubicación',
    AppStrings.allNearby: 'TODOS CERCA',
    AppStrings.directions: 'Cómo llegar',
    AppStrings.go: 'Ir',
    AppStrings.openNow: 'Abierto ahora',
    AppStrings.openLabel: 'Abierto',
    AppStrings.closedLabel: 'Cerrado',
    AppStrings.foundALocation: 'Ya encontré un lugar',

    AppStrings.paymentPending: 'Pago pendiente',
    AppStrings.waitingForPayment: 'Esperando el pago',
    AppStrings.waitingForPaymentBody:
        'Completa tu pago en un agente cercano usando el código de abajo',
    AppStrings.timeRemaining: 'Tiempo restante',
    AppStrings.codeValidFrom: 'Código válido por @hours horas desde su emisión',
    AppStrings.autoChecking: 'Comprobando cada @seconds segundos',
    AppStrings.checkPaymentStatus: 'Comprobar estado del pago',
    AppStrings.viewNearbyLocations: 'Ver lugares cercanos',

    AppStrings.paymentConfirmed: '¡Pago confirmado!',
    AppStrings.paymentConfirmedBody:
        'Tu reserva está confirmada y tus medicamentos se están preparando.',
    AppStrings.bookingDetails: 'DETALLES DE LA RESERVA',
    AppStrings.orderId: 'N.º de pedido',
    AppStrings.date: 'Fecha',
    AppStrings.estimatedDelivery: 'Entrega estimada',
    AppStrings.pharmacyLabel: 'Farmacia',
    AppStrings.prescription: 'Receta',
    AppStrings.medicinesCount: 'MEDICAMENTOS (@count)',
    AppStrings.totalPaid: 'Total pagado',
    AppStrings.paidViaCash: 'Pagado en efectivo en agente • Código @code',
    AppStrings.goHome: 'Ir al inicio',

    // Chat
    AppStrings.online: 'En línea',
    AppStrings.typeYourMessage: 'Escribe tu mensaje...',

    // Citas
    AppStrings.myAppointments: 'Mis citas',
    AppStrings.upcoming: 'Próximas',
    AppStrings.past: 'Pasadas',
    AppStrings.noAppointmentsYet: 'Aún no tienes citas',
    AppStrings.findADoctor: 'Buscar un médico',
    AppStrings.joinOpensSoon: 'Puedes unirte 15 minutos antes de tu cita',

    // Farmacia
    AppStrings.pharmacyTitle: 'Farmacia',
    AppStrings.pharmacySubtitle: 'Medicamentos con receta, a domicilio',
    AppStrings.addToCart: 'Añadir',
    AppStrings.addedToCart: 'Añadido a tu carrito',
    AppStrings.inStock: 'Disponible',
    AppStrings.outOfStock: 'Agotado',

    // Mensajes
    AppStrings.otpResent: 'Enviamos un nuevo código',
    AppStrings.somethingWentWrong: 'Algo salió mal. Inténtalo de nuevo.',
    AppStrings.noInternetConnection: 'Sin conexión a internet',
  };
}
