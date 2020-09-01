public with sharing class ApexTriggerUtility {
    public static Boolean Estimate_Line_Update_Price_Value = true;
    public static Boolean Estimate_Line_Update_Price_Is_Enabled { get {return Estimate_Line_Update_Price_Value;}}
    
    public static boolean isInvoiceLineTriggerInvoked = true;
}