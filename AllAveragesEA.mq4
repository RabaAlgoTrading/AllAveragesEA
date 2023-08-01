// Libs.
#include <AllAveragesEA.mqh>

//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
{  
   // Skip if not enough bars.
   if (Bars < InpSlowMA_Period || (InpSLPlacement == SLAtLastHighLow && Bars < fmax(InpLastHighLowDistance, InpSlowMA_Period))) return;

   // Skip if spread is greater than allowed.
   if (MarketInfo(Symbol(), MODE_SPREAD) > InpMaxSpread) return;
   
   // For every new bar.
   if (NewBar()) {
   
      // Check buy signal (slow trend is bullish, fast trend just became bullish, fast MA is above slow MA).
      if (GetSlowMATrend(MAShift) > 1 && GetFastMATrend(MAShift) > 0 && GetFastMATrend(MAShift + 1) < 0 && GetFastMAValue(1) > GetSlowMAValue(1)) {
         
         // Close last position if needed.
         if (InpTPMethod == TPCloseByOpositeSignal) {
            if (!CloseLastPosition()) LogIfAnyError();
            Print("Opposite signal close sell");
         }
         
         // Exec buy if max simultaneous positions not reached.
         if (OrdersTotal() < InpMaxSimultaneousPositions) {
            if (Buy() == -1) LogIfAnyError();
         }         
      }
      
      // Check sell signal (slow trend is bearish, fast trend just became bearish, fast MA is below slow MA).
      if (GetSlowMATrend(MAShift) < 1 && GetFastMATrend(MAShift) < 0 && GetFastMATrend(MAShift + 1) > 0 && GetFastMAValue(1) < GetSlowMAValue(1)) {
         
         // Close last position if needed.
         if (InpTPMethod == TPCloseByOpositeSignal) {
            if (!CloseLastPosition()) LogIfAnyError();
            Print("Opposite signal close buy");
         }
         
         // Exec sell if max simultaneous positions not reached.
         if (OrdersTotal() < InpMaxSimultaneousPositions) {
            if (Sell() == -1) LogIfAnyError();
         }
      }
   }

   // Update trailing stops if enabled.
   if (InpEnableTSL) UpdateTrailingStops();
}

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
{ 
   return(INIT_SUCCEEDED);
}

//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
{
   Print("Expert deinitialized. Reason: ", reason);
}
