module.exports = {
  content: [
    './app/views/**/*.html.erb',
    './app/helpers/**/*.rb',
    './app/assets/javascripts/**/*.js'
  ],
  theme: {
    extend: {
      colors: {
        'terracotta': '#C2623F',      // Primary brand color
        'terracotta-light': '#D97E5C',
        'terracotta-dark': '#A5502F',
        'beige': '#F5E6D3',            // Secondary color
        'beige-dark': '#E8D4BB',
        'dark-bg': '#1A1A1A',          // Near-black background
        'moutarde': '#D4A017',         // Jaune moutarde pour Markdown maker
        'moutarde-dark': '#B8860B',
      },
      fontFamily: {
        'script': ['Georgia', 'serif'],  // Elegant italic for titles/logo
        'sans': ['Inter', 'system-ui', 'sans-serif'],  // Body text
      },
      screens: {
        'xs': '390px',   // iPhone 12 Pro mobile reference
        'sm': '640px',
        'md': '768px',   // Tablet
        'lg': '1024px',  // Desktop sidebar visible
        'xl': '1280px',
        '2xl': '1728px', // MacBook Pro 16" reference
      }
    }
  },
  plugins: []
}
