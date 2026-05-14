# Design Deep Analysis - "Suggest a Property"

Based on the provided design images and the project's existing UI/UX standards in `AppTheme`, I have identified the following key areas for improvement.

## 1. Typography & Visual Hierarchy
- **Project Standard**: Uses 'Outfit' throughout. Titles are bold and prominent.
- **Improvement**: Standardize all headers using `AppTheme.font2XL` for main titles and `AppTheme.fontBase` with `FontWeight.w600` for field labels.
- **Refinement**: Ensure the "Suggest a Property" title on the Intro screen is centered and matches the Figma's bold weight.

## 2. Component Fidelity
- **Cards**: The project uses `radiusLG` (16.0) or `radiusXL` (20.0). The benefit cards in the design have a very specific rounded look (approx 20.0).
- **Steppers**: The custom stepper needs to have a specific navy-blue active state and a light-gray inactive state (`Color(0xFFE2E8F0)`).
- **Identity Selection**: The "Student" vs "Professional" cards need a distinct active border (`AppTheme.primaryColor`) and a subtle background tint (`0.05` opacity).

## 3. Interactive UX
- **Form Navigation**: Instead of one long scroll, the 3-step indicator implies a focused 3-page experience. I will implement a `PageView` to reduce cognitive load, matching the "List Your Property" flow.
- **Animations**: Entry animations (fades and slides) using `flutter_animate` will be added to cards and form sections to match the project's premium feel.
- **Success Feedback**: The success screen needs the green confetti look and a recap card that stands out against the white background.

## 4. Brand Alignment
- **Primary Color**: Switching placeholder colors to `AppTheme.primaryColor` (0xFF314E7D).
- **Icons**: Using `Icons.person_outline_rounded`, `Icons.email_outlined`, etc., to match the project's icon style.
- **Secure Footer**: Every form screen will feature the "Your information is safe and secure" footer with the lock icon.

## Planned Screen Refinements

### Intro Screen
- Add a custom house illustration with the blue location pin.
- Improve the benefit cards with subtle shadows (`blurRadius: 15, offset: Offset(0, 8)` with low opacity).

### Form Screen
- Implement a 3-step `PageView`.
- **Step 1**: Who are you? + Your Details.
- **Step 2**: Business Owner Details.
- **Step 3**: Business Info & Address.
- Add real-time validation and a "Continue" button that shows the next step.

### Success Screen
- Add a big green checkmark circle with a scale animation.
- Polish the timeline component with `IntrinsicHeight` and vertical dividers.
- Add a "Suggest Another Property" outlined button using `AppTheme.primaryColor`.
