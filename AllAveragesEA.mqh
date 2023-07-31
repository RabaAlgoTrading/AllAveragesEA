//+------------------------------------------------------------------+
//|                                        Copyright 2023, mapapel78 |
//|                                   raba.algotrading@instagram.com |
//+------------------------------------------------------------------+
#property copyright     "Copyright 2023, mapapel78"
#property link          "raba.algotrading@instagram.com"     // Autors professional instagram
#property strict

// Include indicators to the expert compiled file.
#define AllAveragesIndicator "Indicators\\AllAverages v4.9.ex4"
#resource "\\" + AllAveragesIndicator

// Libs.
#include <stdlib.mqh>
#include <math_utils.mqh>

// Structures.
enum ENUM_MA_MODE
{
   SMA,                 // Simple Moving Average
   EMA,                 // Exponential Moving Average
   Wilder,              // Wilder Exponential Moving Average
   LWMA,                // Linear Weighted Moving Average
   SineWMA,             // Sine Weighted Moving Average
   TriMA,               // Triangular Moving Average
   LSMA,                // Least Square Moving Average (or EPMA, Linear Regression Line)
   SMMA,                // Smoothed Moving Average
   HMA,                 // Hull Moving Average by A.Hull
   ZeroLagEMA,          // Zero-Lag Exponential Moving Average
   DEMA,                // Double Exponential Moving Average by P.Mulloy
   T3_basic,            // T3 by T.Tillson (original version)
   ITrend,              // Instantaneous Trendline by J.Ehlers
   Median,              // Moving Median
   GeoMean,             // Geometric Mean
   REMA,                // Regularized EMA by C.Satchwell
   ILRS,                // Integral of Linear Regression Slope
   IE_2,                // Combination of LSMA and ILRS
   TriMAgen,            // Triangular Moving Average generalized by J.Ehlers
   VWMA,                // Volume Weighted Moving Average
   JSmooth,             // M.Jurik's Smoothing
   SMA_eq,              // Simplified SMA
   ALMA,                // Arnaud Legoux Moving Average
   TEMA,                // Triple Exponential Moving Average by P.Mulloy
   T3,                  // T3 by T.Tillson (correct version)
   Laguerre,            // Laguerre filter by J.Ehlers
   MD,                  // McGinley Dynamic
   BF2P,                // Two-pole modified Butterworth filter by J.Ehlers
   BF3P,                // Three-pole modified Butterworth filter by J.Ehlers
   SuperSmu,            // SuperSmoother by J.Ehlers
   Decycler,            // Simple Decycler by J.Ehlers
   eVWMA,               // Modified eVWMA
   EWMA,                // Exponential Weighted Moving Average
   DsEMA,               // Double Smoothed EMA
   TsEMA,               // Triple Smoothed EMA
   VEMA                 // Volume-weighted Exponential Moving Average(V-EMA)
};   

enum ENUM_PRICE
{
   close,               // Close
   open,                // Open
   high,                // High
   low,                 // Low
   median,              // Median
   typical,             // Typical
   weightedClose,       // Weighted Close
   medianBody,          // Median Body (Open+Close)/2
   average,             // Average (High+Low+Open+Close)/4
   trendBiased,         // Trend Biased
   trendBiasedExt,      // Trend Biased(extreme)
   haClose,             // Heiken Ashi Close
   haOpen,              // Heiken Ashi Open
   haHigh,              // Heiken Ashi High   
   haLow,               // Heiken Ashi Low
   haMedian,            // Heiken Ashi Median
   haTypical,           // Heiken Ashi Typical
   haWeighted,          // Heiken Ashi Weighted Close
   haMedianBody,        // Heiken Ashi Median Body
   haAverage,           // Heiken Ashi Average
   haTrendBiased,       // Heiken Ashi Trend Biased
   haTrendBiasedExt     // Heiken Ashi Trend Biased(extreme)   
};

enum ENUM_TP_METHOD
{
   TPFixedBalance,         // Fixed balance
   TPFixedBalancePerc,     // Fixed balance percentage
   TPCloseByOpositeSignal  // Close by opposite signal
};

enum ENUM_SL_RISK_METHOD
{
   SLFixedLots,            // Fixed lots
   SLFixedBalance,         // Fixed balance
   SLFixedBalancePerc      // Fixed balance percentage
};

enum ENUM_SL_PLACEMENT
{
   SLAtMA,                 // At the fast moving average
   SLAtLastHighLow,        // At last high-low (last x bars)
};

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

sinput group "### EXPERT CONFIG ###"
input int                  InpExpertMagic                = 54454564;             // Expert magic number

// Globals.
int lastNumberOfBars = 0;
int maxSlippage = 100;

// Returns true if a new bar has been started, false if not.
bool NewBar()
{
   if (lastNumberOfBars < Bars) {
      lastNumberOfBars = Bars;
      return true;
   }
   return false;
}

// Places a buy position according to the inputs. Returns position ticket or -1 if any error.
ulong Buy()
{
   double sl = CalcStopLoss(OP_BUY, Ask);   
   double volume = CalcVolume(Ask, sl);
   double tp = CalcTakeProfit(OP_BUY, Ask, volume);
   
   return OrderSend(_Symbol, OP_BUY, volume, Ask, maxSlippage, sl, tp, "", InpExpertMagic);
}

// Places a sell position according to the inputs. Returns position ticket or -1 if any error.
ulong Sell()
{
   double sl = CalcStopLoss(OP_SELL, Bid);   
   double volume = CalcVolume(Bid, sl);
   double tp = CalcTakeProfit(OP_SELL, Bid, volume);

   return OrderSend(_Symbol, OP_SELL, volume, Bid, maxSlippage, sl, tp, "", InpExpertMagic);
}

// Calculates and returns the stop loss price according to the inputs.
double CalcStopLoss(ENUM_ORDER_TYPE pOrderType, double pOpenPrice)
{
   double sl = 0;
   
   // Case set SL at fixed pips.
   if (InpSLPlacement == SLAtMA) {
      if (pOrderType == OP_BUY && GetFastMAValue(1) < pOpenPrice) sl = GetFastMAValue(1) - InpSLMargin * _Point;
      else if (pOrderType == OP_BUY && GetFastMAValue(1) >= pOpenPrice) sl = GetSlowMAValue(1) - InpSLMargin * _Point;     // Use slow MA is price is below fast MA.
      else if (pOrderType == OP_SELL && GetFastMAValue(1) > pOpenPrice) sl = GetFastMAValue(1) + InpSLMargin * _Point;
      else if (pOrderType == OP_SELL && GetFastMAValue(1) <= pOpenPrice) sl = GetSlowMAValue(1) + InpSLMargin * _Point;    // Use slow MA is price is above fast MA.
   } else if (InpSLPlacement == SLAtLastHighLow) {
      double lastHigh = iHigh(_Symbol, _Period, iHighest(_Symbol, _Period, MODE_HIGH, InpLastHighLowDistance, 0));
      double lastLow = iLow(_Symbol, _Period, iLowest(_Symbol, _Period, MODE_LOW, InpLastHighLowDistance, 0));
      if (pOrderType == OP_BUY) sl = lastLow - InpSLMargin * _Point;
      else if (pOrderType == OP_SELL) sl = lastHigh + InpSLMargin * _Point;
   }
   return NormalizeDouble(sl, _Digits);
}

// Calculates and returns the position volume according to the inputs
double CalcVolume(double pOpenPrice, double pStopLoss)
{
   double lotsMin = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MIN);
   double lotsMax = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MAX);
   double volume = lotsMin;
   
   if (InpSLRiskMethod == SLFixedLots) {
      volume = InpSLRiskValue;
   } else if (InpSLRiskMethod == SLFixedBalance) {
      volume = CalcVolumeByRiskBalance(InpSLRiskValue, MathAbs(pOpenPrice - pStopLoss));
   } else if (InpSLRiskMethod == SLFixedBalancePerc) {
      volume = CalcVolumeByRiskPerc(InpSLRiskValue, MathAbs(pOpenPrice - pStopLoss));
   }
   return NormalizeDouble(fmin(fmax(volume, lotsMin), lotsMax), GetDigits(SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MIN)));
}

// Calculates and returns the lots required to risk the specified percentage of the account balance. 
double CalcVolumeByRiskPerc(double pRiskPerc, double pSlDistance)
{   
   double riskBalance = AccountInfoDouble(ACCOUNT_BALANCE) * pRiskPerc / 100; 
   return CalcVolumeByRiskBalance(riskBalance, pSlDistance);
}

// Calculates and returns the lots required to risk the specified amount of the account balance. 
double CalcVolumeByRiskBalance(double pRiskBalance, double pSlDistance)
{
   double tickSize = MarketInfo(_Symbol, MODE_TICKSIZE);
   double tickValue = MarketInfo(_Symbol, MODE_TICKVALUE);
   double point = MarketInfo(_Symbol, MODE_POINT);
   double ticksPerPoint = tickSize / point;
   double pointValue = tickValue / ticksPerPoint;   
   double lots = pRiskBalance / (pointValue * pSlDistance) * _Point;  
   return lots;
}

// Calculates and returns the take profit price according to the inputs.
double CalcTakeProfit(ENUM_ORDER_TYPE pOrderType, double pOpenPrice, double pVolume)
{
   double tp = 0;

   if (InpTPMethod == TPFixedBalance) {
      if (pOrderType == OP_BUY) tp = pOpenPrice + CalcTPPointsByBalance(InpTPValue, pVolume);
      else if (pOrderType == OP_SELL) tp = pOpenPrice - CalcTPPointsByBalance(InpTPValue, pVolume);
   } else if (InpTPMethod == TPFixedBalancePerc) {
      double tpValue = InpTPValue / AccountInfoDouble(ACCOUNT_BALANCE) * 100;
      if (pOrderType == OP_BUY) tp = pOpenPrice + CalcTPPointsByPerc(InpTPValue, pVolume);
      else if (pOrderType == OP_SELL) tp = pOpenPrice - CalcTPPointsByPerc(InpTPValue, pVolume);
   } else if (InpTPMethod == TPCloseByOpositeSignal) {
      // Nothing to do.
   }
   return NormalizeDouble(tp, _Digits);
}

// Calculates and returns the tp points required to win the specified percentage of the account balance. 
double CalcTPPointsByPerc(double pPerc, double pVolume)
{   
   double balance = AccountInfoDouble(ACCOUNT_BALANCE) * pPerc / 100; 
   return CalcTPPointsByBalance(balance, pVolume);
}

// Calculates and returns the tp points required to win the specified amount of the account balance. 
double CalcTPPointsByBalance(double pBalance, double pVolume)
{
   double tickSize = MarketInfo(_Symbol, MODE_TICKSIZE);
   double tickValue = MarketInfo(_Symbol, MODE_TICKVALUE);
   double point = MarketInfo(_Symbol, MODE_POINT);
   double ticksPerPoint = tickSize / point;
   double pointValue = tickValue / ticksPerPoint;
   double points = pBalance / (pointValue * pVolume) * _Point;
   return points;
}

// Deletes last position. Returns true if successfull, false if not.
bool CloseLastPosition()
{
   if (OrderSelect(OrdersTotal() - 1, SELECT_BY_POS)) {
      if (OrderType() == OP_BUY) {
         return OrderClose(OrderTicket(), OrderLots(), Bid, maxSlippage, Blue);
      } else if (OrderType() == OP_SELL) {
         return OrderClose(OrderTicket(), OrderLots(), Ask, maxSlippage, Red);
      }  
   } 
   return false;
}

// Updates required trailing stops.
void UpdateTrailingStops()
{
   double lastHigh = NULL;
   double lastLow = NULL;
   
   // Init last high-low if required.
   if (InpSLPlacement == SLAtLastHighLow){
      lastHigh = iHighest(_Symbol, _Period, MODE_HIGH, WHOLE_ARRAY, InpLastHighLowDistance);
      lastLow = iLowest(_Symbol, _Period, MODE_LOW, WHOLE_ARRAY, InpLastHighLowDistance);
   }
         
   // Loop all positions.
   for (int i = 0; i < OrdersTotal(); i++) {
      
      // Skip if failed selecting.
      if (!OrderSelect(i, SELECT_BY_POS)) { 
         LogIfAnyError();
         continue;
      }
      
      // Case set SL to last fastMA price.   
      if (InpSLPlacement == SLAtMA) {
         if (OrderType() == OP_BUY && OrderStopLoss() < GetFastMAValue(1)) {
            if (!OrderModify(OrderTicket(), OrderOpenPrice(), NormalizeDouble(GetFastMAValue(1), _Digits), OrderTakeProfit(), 0)) LogIfAnyError();
         } else if (OrderType() == OP_SELL && OrderStopLoss() > GetFastMAValue(1)) {
            if (!OrderModify(OrderTicket(), OrderOpenPrice(), NormalizeDouble(GetFastMAValue(1), _Digits), OrderTakeProfit(), 0)) LogIfAnyError();
         }
               
      // Case set SL to the last high-low.
      } else if (InpSLPlacement == SLAtLastHighLow) {     
         if (OrderType() == OP_BUY && OrderStopLoss() < lastLow) {
            if (!OrderModify(OrderTicket(), OrderOpenPrice(), NormalizeDouble(lastLow, _Digits), OrderTakeProfit(), 0)) LogIfAnyError();
         } else if (OrderType() == OP_SELL && OrderStopLoss() > lastHigh) {
            if (!OrderModify(OrderTicket(), OrderOpenPrice(), NormalizeDouble(lastHigh, _Digits), OrderTakeProfit(), 0)) LogIfAnyError();
         }
      }
   }
}

// Checks if any error occured and pops a message.
void LogIfAnyError(bool pPopUp = true)
{
   if (GetLastError() != 0) {
      string errorMsg = "Error " + string(GetLastError()) + ": " + ErrorDescription(GetLastError());
      if (pPopUp) MessageBox(errorMsg);      
      Print(errorMsg);
      ResetLastError();
   }
}

// Returns fast MA trend (1 bullish, -1 bearish) of pShift bar.
double GetFastMATrend(int pShift)
{  
   return iCustom(_Symbol, _Period, "::" + AllAveragesIndicator,
                        _Period,                   // TimeFrame
                        InpFastMA_Price,           // Price
                        InpFastMA_Period,          // MA_Period
                        0,                         // MA_Shift
                        InpFastMA_Method,          // MA_Method
                        true,                      // ShowInColor
                        0,                         // CountBars
                        "",                        // Alerts
                        false,                     // AlertOn
                        1,                         // AlertShift
                        5,                         // SoundsNumber
                        5,                         // SoundsPause
                        "",                        // UpTrendSound
                        "",                        // DnTrendSound
                        false,                     // EmailOn
                        1,                         // EmailsNumber
                        false,                     // PushNotificationOn    
                        4,                         // buffer
                        pShift                     // shift
                  );        
}

// Returns slow MA trend (1 bullish, -1 bearish) of pShift bar.
double GetSlowMATrend(int pShift)
{
   return iCustom(_Symbol, _Period, "::" + AllAveragesIndicator,
                        _Period,                   // TimeFrame
                        InpSlowMA_Price,           // Price
                        InpSlowMA_Period,          // MA_Period
                        0,                         // MA_Shift
                        InpSlowMA_Method,          // MA_Method
                        true,                      // ShowInColor
                        0,                         // CountBars
                        "",                        // Alerts
                        false,                     // AlertOn
                        1,                         // AlertShift
                        5,                         // SoundsNumber
                        5,                         // SoundsPause
                        "",                        // UpTrendSound
                        "",                        // DnTrendSound
                        false,                     // EmailOn
                        1,                         // EmailsNumber
                        false,                     // PushNotificationOn    
                        4,                         // buffer
                        pShift                     // shift
                  );        
}

// Returns fast MA value of pShift bar.
double GetFastMAValue(int pShift)
{  
   return iCustom(_Symbol, _Period, "::" + AllAveragesIndicator,
                        _Period,                   // TimeFrame
                        InpFastMA_Price,           // Price
                        InpFastMA_Period,          // MA_Period
                        0,                         // MA_Shift
                        InpFastMA_Method,          // MA_Method
                        true,                      // ShowInColor
                        0,                         // CountBars
                        "",                        // Alerts
                        false,                     // AlertOn
                        1,                         // AlertShift
                        5,                         // SoundsNumber
                        5,                         // SoundsPause
                        "",                        // UpTrendSound
                        "",                        // DnTrendSound
                        false,                     // EmailOn
                        1,                         // EmailsNumber
                        false,                     // PushNotificationOn    
                        3,                         // buffer
                        pShift                     // shift
                  );        
}

// Returns slow MA value of pShift bar.
double GetSlowMAValue(int pShift)
{
   return iCustom(_Symbol, _Period, "::" + AllAveragesIndicator,
                        _Period,                   // TimeFrame
                        InpSlowMA_Price,           // Price
                        InpSlowMA_Period,          // MA_Period
                        0,                         // MA_Shift
                        InpSlowMA_Method,          // MA_Method
                        true,                      // ShowInColor
                        0,                         // CountBars
                        "",                        // Alerts
                        false,                     // AlertOn
                        1,                         // AlertShift
                        5,                         // SoundsNumber
                        5,                         // SoundsPause
                        "",                        // UpTrendSound
                        "",                        // DnTrendSound
                        false,                     // EmailOn
                        1,                         // EmailsNumber
                        false,                     // PushNotificationOn    
                        3,                         // buffer
                        pShift                     // shift
                  );   
}