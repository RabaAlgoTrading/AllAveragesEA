// Libs.
#include <AllAveragesEA.mqh>

// Inputs.
sinput group "### STRATEGY CONFIG ###"
input ENUM_MA_MODE         InpFastMA_Method              = SMA;                  // Fast MA method
input int                  InpFastMA_Period              = 24;                   // Fast MA period
input ENUM_PRICE           InpFastMA_Price               = close;                // Fast MA applied price
input ENUM_MA_MODE         InpSlowMA_Method              = SMA;                  // Slow MA method
input int                  InpSlowMA_Period              = 165;                  // Slow MA period
input ENUM_PRICE           InpSlowMA_Price               = close;                // Slow MA applied price

sinput group "### RISK MANAGEMENT ###"
input ENUM_SL_RISK_METHOD  InpSLRiskMethod               = SLFixedBalancePerc;   // Stop loss risk method
input double               InpSLRiskValue                = 1;                    // Stop loss risk value
input ENUM_SL_PLACEMENT    InpSLPlacement                = SLAtLastHighLow;      // Stop loss placement
input int                  InpSLMargin                   = 0;                    // Stop loss margin (points)
input int                  InpLastHighLowDistance        = 24;                   // Last high-low distance in bars
input bool                 InpEnableTSL                  = true;                 // Use trailing stop loss
input ENUM_TP_METHOD       InpTPMethod                   = TPFixedBalancePerc;   // Take profit method
input double               InpTPValue                    = 1;                    // Take profit value
input int                  InpMaxSimultaneousPositions   = 1;                    // Max. simultaneous positions
input int                  InpMaxSlippage                = 100;                  // Max. allowed slippage (points)
input int                  InpMaxSpread                  = 25;                   // Max. allowed spread (points)

sinput group "### EXPERT CONFIG ###"
input int                  InpExpertMagic                = 54454564;             // Expert magic number

// Globals.
int lastNumberOfBars = 0;
int MAShift = 1;

//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
{  
   // Skip if not enough bars.
   if (Bars < InpSlowMA_Period || (InpSLPlacement == SLAtLastHighLow && Bars < fmax(InpLastHighLowDistance, InpSlowMA_Period))) return;

   // Skip if spread is greater than allowed.
   if (MarketInfo(Symbol(), MODE_SPREAD) > InpMaxSpread && InpMaxSpread != 0) return;
   
   // For every new bar.
   if (NewBar()) {
      
      // Check buy signal (slow trend is bullish, fast trend just became bullish, fast MA is above slow MA).
      if (GetSlowMATrend(MAShift) > 0 && GetFastMATrend(MAShift) > 0 && GetFastMATrend(MAShift + 1) < 0 && (GetFastMAValue(MAShift) > GetSlowMAValue(MAShift) || !InpEnableOrderedMAFilter)) {

         // Close all sell positions if needed.
         if (InpTPMethod == TPCloseByOpositeSignal) ClosePositionsByType(OP_SELL);
         
         // Exec buy if max simultaneous positions not reached.
         if (OrdersTotal() < InpMaxSimultaneousPositions || InpMaxSimultaneousPositions == 0) {
            if (Buy() == -1) LogIfAnyError();
         }         
      }
      
      // Check sell signal (slow trend is bearish, fast trend just became bearish, fast MA is below slow MA).
      if (GetSlowMATrend(MAShift) < 0 && GetFastMATrend(MAShift) < 0 && GetFastMATrend(MAShift + 1) > 0 && (GetFastMAValue(MAShift) < GetSlowMAValue(MAShift) || !InpEnableOrderedMAFilter)) {

         // Close all buy positions if needed.
         if (InpTPMethod == TPCloseByOpositeSignal) ClosePositionsByType(OP_BUY);
         
         // Exec sell if max simultaneous positions not reached.
         if (OrdersTotal() < InpMaxSimultaneousPositions || InpMaxSimultaneousPositions == 0) {
            if (Sell() == -1) LogIfAnyError();
         }
      }  
      
      // Update trailing stops.
      if (InpEnableTSL && OrdersTotal() > 0) UpdateTrailingStops();
   }
}

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
{ 
   // If MA price mode is open we can use shift 0. Else 1.
   MAShift = (InpFastMA_Price == open && InpSlowMA_Price == open) ? 0 : 1;
   return(INIT_SUCCEEDED);
}

//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
{
   Print("Expert deinitialized. Reason: ", reason);
}
