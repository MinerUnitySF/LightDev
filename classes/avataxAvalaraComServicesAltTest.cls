@isTest
public with sharing class avataxAvalaraComServicesAltTest {

	private static testmethod void test1(){
		
		Key_Value_Store__c kvs = new Key_Value_Store__c();
		kvs.Name = 'Avatax URL';
		kvs.Value__c = 'https://avatax.avalara.net';
		insert kvs;
		
		avataxAvalaraComServicesAlt av = new avataxAvalaraComServicesAlt();
		
		avataxAvalaraComServicesAlt.AuditMessage m1 = new avataxAvalaraComServicesAlt.AuditMessage();
		avataxAvalaraComServicesAlt.CommitTaxResult m2 = new avataxAvalaraComServicesAlt.CommitTaxResult();
		avataxAvalaraComServicesAlt.IsAuthorized_element m3 = new avataxAvalaraComServicesAlt.IsAuthorized_element();
		avataxAvalaraComServicesAlt.TaxAddress m4 = new avataxAvalaraComServicesAlt.TaxAddress();
		avataxAvalaraComServicesAlt.ArrayOfMessage m5 = new avataxAvalaraComServicesAlt.ArrayOfMessage();
		avataxAvalaraComServicesAlt.ArrayOfLine m6 = new avataxAvalaraComServicesAlt.ArrayOfLine();
		avataxAvalaraComServicesAlt.ApplyPaymentResponse_element m7 = new avataxAvalaraComServicesAlt.ApplyPaymentResponse_element();
		avataxAvalaraComServicesAlt.GetTaxHistoryResult m8 = new avataxAvalaraComServicesAlt.GetTaxHistoryResult();
		avataxAvalaraComServicesAlt.ArrayOfBaseAddress m9 = new avataxAvalaraComServicesAlt.ArrayOfBaseAddress();
		avataxAvalaraComServicesAlt.PostTax_element m10 = new avataxAvalaraComServicesAlt.PostTax_element();
		avataxAvalaraComServicesAlt.PostTaxRequest m11 = new avataxAvalaraComServicesAlt.PostTaxRequest();
		avataxAvalaraComServicesAlt.AdjustTaxRequest m12 = new avataxAvalaraComServicesAlt.AdjustTaxRequest();
		avataxAvalaraComServicesAlt.ArrayOfTaxLine m13 = new avataxAvalaraComServicesAlt.ArrayOfTaxLine();
		avataxAvalaraComServicesAlt.ApplyPaymentRequest m14 = new avataxAvalaraComServicesAlt.ApplyPaymentRequest();
		avataxAvalaraComServicesAlt.PingResult m15 = new avataxAvalaraComServicesAlt.PingResult();
		avataxAvalaraComServicesAlt.IsAuthorizedResult m16 = new avataxAvalaraComServicesAlt.IsAuthorizedResult();
		avataxAvalaraComServicesAlt.IsAuthorizedResponse_element m17 = new avataxAvalaraComServicesAlt.IsAuthorizedResponse_element();
		avataxAvalaraComServicesAlt.CommitTaxRequest m18 = new avataxAvalaraComServicesAlt.CommitTaxRequest();
		avataxAvalaraComServicesAlt.TaxOverride m19 = new avataxAvalaraComServicesAlt.TaxOverride();
		avataxAvalaraComServicesAlt.Profile m20 = new avataxAvalaraComServicesAlt.Profile();
		avataxAvalaraComServicesAlt.ReconcileTaxHistoryRequest m21 = new avataxAvalaraComServicesAlt.ReconcileTaxHistoryRequest();
		avataxAvalaraComServicesAlt.BaseResult m22 = new avataxAvalaraComServicesAlt.BaseResult();
		avataxAvalaraComServicesAlt.ApplyPaymentResult m23 = new avataxAvalaraComServicesAlt.ApplyPaymentResult();
		avataxAvalaraComServicesAlt.ArrayOfTaxDetail m24 = new avataxAvalaraComServicesAlt.ArrayOfTaxDetail();
		avataxAvalaraComServicesAlt.BaseAddress m25 = new avataxAvalaraComServicesAlt.BaseAddress();
		avataxAvalaraComServicesAlt.Security m26 = new avataxAvalaraComServicesAlt.Security();
		avataxAvalaraComServicesAlt.GetTaxHistoryResponse_element m27 = new avataxAvalaraComServicesAlt.GetTaxHistoryResponse_element();
		avataxAvalaraComServicesAlt.GetTax_element m28 = new avataxAvalaraComServicesAlt.GetTax_element();
		avataxAvalaraComServicesAlt.UsernameToken_element m29 = new avataxAvalaraComServicesAlt.UsernameToken_element();
		avataxAvalaraComServicesAlt.AdjustTaxResult m30 = new avataxAvalaraComServicesAlt.AdjustTaxResult();
		avataxAvalaraComServicesAlt.GetTaxResult m31 = new avataxAvalaraComServicesAlt.GetTaxResult();
		avataxAvalaraComServicesAlt.CommitTax_element m32 = new avataxAvalaraComServicesAlt.CommitTax_element();
		avataxAvalaraComServicesAlt.ReconcileTaxHistoryResult m33 = new avataxAvalaraComServicesAlt.ReconcileTaxHistoryResult();
		avataxAvalaraComServicesAlt.AdjustTax_element m34 = new avataxAvalaraComServicesAlt.AdjustTax_element();
		avataxAvalaraComServicesAlt.AdjustTaxResponse_element m35 = new avataxAvalaraComServicesAlt.AdjustTaxResponse_element();
		avataxAvalaraComServicesAlt.Ping_element m36 = new avataxAvalaraComServicesAlt.Ping_element();
		avataxAvalaraComServicesAlt.GetTaxHistory_element m37 = new avataxAvalaraComServicesAlt.GetTaxHistory_element();
		avataxAvalaraComServicesAlt.TaxSvcAltSecSoap m38 = new avataxAvalaraComServicesAlt.TaxSvcAltSecSoap();
		avataxAvalaraComServicesAlt.ArrayOfTaxAddress m39 = new avataxAvalaraComServicesAlt.ArrayOfTaxAddress();
		avataxAvalaraComServicesAlt.PostTaxResponse_element m40 = new avataxAvalaraComServicesAlt.PostTaxResponse_element();
		avataxAvalaraComServicesAlt.GetTaxRequest m41 = new avataxAvalaraComServicesAlt.GetTaxRequest();
		avataxAvalaraComServicesAlt.CancelTax_element m42 = new avataxAvalaraComServicesAlt.CancelTax_element();
		avataxAvalaraComServicesAlt.CommitTaxResponse_element m43 = new avataxAvalaraComServicesAlt.CommitTaxResponse_element();
		avataxAvalaraComServicesAlt.PostTaxResult m44 = new avataxAvalaraComServicesAlt.PostTaxResult();
		avataxAvalaraComServicesAlt.ReconcileTaxHistoryResponse_element m45 = new avataxAvalaraComServicesAlt.ReconcileTaxHistoryResponse_element();
		avataxAvalaraComServicesAlt.CancelTaxResult m46 = new avataxAvalaraComServicesAlt.CancelTaxResult();
		avataxAvalaraComServicesAlt.TaxDetail m47 = new avataxAvalaraComServicesAlt.TaxDetail();
		avataxAvalaraComServicesAlt.Message m48 = new avataxAvalaraComServicesAlt.Message();
		avataxAvalaraComServicesAlt.PingResponse_element m49 = new avataxAvalaraComServicesAlt.PingResponse_element();
		avataxAvalaraComServicesAlt.GetTaxHistoryRequest m50 = new avataxAvalaraComServicesAlt.GetTaxHistoryRequest();
		avataxAvalaraComServicesAlt.ApplyPayment_element m51 = new avataxAvalaraComServicesAlt.ApplyPayment_element();
		avataxAvalaraComServicesAlt.CancelTaxRequest m52 = new avataxAvalaraComServicesAlt.CancelTaxRequest();
		avataxAvalaraComServicesAlt.ReconcileTaxHistory_element m53 = new avataxAvalaraComServicesAlt.ReconcileTaxHistory_element();
		avataxAvalaraComServicesAlt.GetTaxResponse_element m54 = new avataxAvalaraComServicesAlt.GetTaxResponse_element();
		avataxAvalaraComServicesAlt.SearchTaxHistoryResult m55 = new avataxAvalaraComServicesAlt.SearchTaxHistoryResult();
		avataxAvalaraComServicesAlt.CancelTaxResponse_element m56 = new avataxAvalaraComServicesAlt.CancelTaxResponse_element();
		avataxAvalaraComServicesAlt.TaxLine m57 = new avataxAvalaraComServicesAlt.TaxLine();
		avataxAvalaraComServicesAlt.ArrayOfGetTaxResult m58 = new avataxAvalaraComServicesAlt.ArrayOfGetTaxResult();
		avataxAvalaraComServicesAlt.Line m59 = new avataxAvalaraComServicesAlt.Line();
		
	}

}