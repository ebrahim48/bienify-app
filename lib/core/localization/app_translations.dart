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

    // Feedback
    AppStrings.otpResent: 'A new code is on its way',
    AppStrings.somethingWentWrong: 'Something went wrong. Please try again.',
    AppStrings.noInternetConnection: 'No internet connection',
    AppStrings.comingSoon: 'Coming soon',
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

    // Mensajes
    AppStrings.otpResent: 'Enviamos un nuevo código',
    AppStrings.somethingWentWrong: 'Algo salió mal. Inténtalo de nuevo.',
    AppStrings.noInternetConnection: 'Sin conexión a internet',
    AppStrings.comingSoon: 'Muy pronto',
  };
}
