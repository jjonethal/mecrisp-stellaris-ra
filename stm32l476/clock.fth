\ clock switching for stm32l476

$40021000 constant RCC
$0 RCC + constant RCC_CR                      \ Clock control register
 1 #29 lshift constant RCC_CR_PLLSAI2RDY      \ SAI2 PLL clock ready flag
 1 #28 lshift constant RCC_CR_PLLSAI2ON       \ SAI2 PLL enable
 1 #27 lshift constant RCC_CR_PLLSAI1RDY      \ SAI1 PLL clock ready flag
 1 #26 lshift constant RCC_CR_PLLSAI1ON       \ SAI1 PLL enable
 1 #25 lshift constant RCC_CR_PLLRDY          \ Main PLL clock ready flag
 1 #24 lshift constant RCC_CR_PLLON           \ Main PLL enable
 1 #19 lshift constant RCC_CR_CSSON           \ Clock security system enable
 1 #18 lshift constant RCC_CR_HSEBYP          \ HSE crystal oscillator bypass
 1 #17 lshift constant RCC_CR_HSERDY          \ HSE clock ready flag
 1 #16 lshift constant RCC_CR_HSEON           \ HSE clock enable
 1 #11 lshift constant RCC_CR_HSIASFS         \ HSI16 automatic start from Stop
 1 #10 lshift constant RCC_CR_HSIRDY          \ HSI16 clock ready flag
 1  #9 lshift constant RCC_CR_HSIKERON        \ HSI16 always enable for peripheral kernels.
 1  #8 lshift constant RCC_CR_HSION           \ HSI clock enable
$f  #4 lshift constant RCC_CR_MSIRANGE        \ MSI clock ranges
 1  #3 lshift constant RCC_CR_MSIRGSEL        \ MSI clock range selection
 1  #2 lshift constant RCC_CR_MSIPLLEN        \ MSI clock PLL enable
 1  #1 lshift constant RCC_CR_MSIRDY          \ MSI clock ready flag
 1  #0 lshift constant RCC_CR_MSION           \ MSI clock enable
