#ifndef CEXCEPTION_HPP
#define CEXCEPTION_HPP

#include <C/Common/TRN_Types.h>
#include <C/Common/TRN_API_Config.hpp>

// All C++ standard library and internal header files must be inside these guards.
// C standard header files (e.g. stdio.h) are recommended to be outside of these guards.
#if TRN_ENABLE_HIDE_SYMBOL_DIRECTIVES
#pragma GCC visibility push(hidden)
#endif // TRN_ENABLE_HIDE_SYMBOL_DIRECTIVES

#include <Common/Exception.h>
#include <Common/UString.h>

#ifndef trn
using namespace trn;
#endif

TRN_Exception GetPDFNetException(Common::Exception& ex);
TRN_Exception GetException(std::string& ex);

#if TRN_ENABLE_HIDE_SYMBOL_DIRECTIVES
#pragma GCC visibility pop
#endif // TRN_ENABLE_HIDE_SYMBOL_DIRECTIVES

#define GSCast(state) ((PDF::GState*)state)
#define EleCast(element) ((PDF::Element*)element)
#define ObjCast(obj)	((SDF::Obj*)obj)

#define PDFDocCast(doc)    (*((PDFDoc*)(&doc)))

//heap casts
#define DocCast(doc) (*((SDF::SDFDoc*)doc))
#define ABSCast(abs) (*((PDF::Annot::BorderStyle*)abs))
#define FuncCast(func) (*((PDF::Function*)func))
#define CSCast(cs) (*((PDF::ColorSpace*)cs))
#define FontCast(font) (*((PDF::Font*)font))
#define ERCast(reader) (*((PDF::ElementReader*)reader))
#define EWCast(writer) (*((PDF::ElementWriter*)writer))
#define EBCast(builder) (*((PDF::ElementBuilder*)builder))
#define ShadeCast(shade) (*((PDF::Shading*)shade))
#define FRCast(reader) (*((Filters::FilterReader*)reader))
#define FWCast(writer) (*((Filters::FilterWriter*)writer))
#define PCCast(pattern_color) (*((PDF::PatternColor*)pattern_color))
#define RastCast(rasterizer) (*((PDF::PDFRasterizer*)rasterizer))
#define DrawCast(pdfdraw) (*((PDF::PDFDraw*)pdfdraw))
#define ViewCast(pdfview) (*((PDF::PDFView*)pdfview))
#define ViewCCast(pdfviewctrl) (*((PDF::PDFViewCtrl*)pdfviewctrl))
#define TECast(extractor) (*((PDF::TextExtractor*)extractor))
#define OSetCast(set) (*((SDF::ObjSet*)set))
#define PDFACCast(pdfa) (*((PDFA::PDFACompliance*)pdfa))
#define HLCast(hlt) (*((PDF::Highlights*)hlt))
#define TSCast(ts) (*((PDF::TextSearch*)ts))
#define ContRepCast(cr) (*((PDF::ContentReplacer*)cr))

//direct casts
#define FieldCast(field) (*((PDF::Field*)field))
#define DigSigFieldCast(dsfieldptr) (*((PDF::DigitalSignatureField*)dsfieldptr))
#define DateCast(date) (*((PDF::Date*)date))
#define CPCast(cp) (*((PDF::ColorPt*)cp))
#define RectCast(rect) (*((PDF::Rect*)rect))
#define CICast(item) (*((PDF::Struct::ContentItem*)item))
#define SEleCast(element) (*((PDF::Struct::SElement*)element))
#define M2DCast(matrix) (*((Common::Matrix2D*)matrix))
#define PLblCast(label) (*((PDF::PageLabel*)label))
#define FFieldCast(field) (*((FDF::FDFField*)field))
#define VSCast(pdfviewselection) (*((PDF::PDFView::Selection*)pdfviewselection))
#define TESCast(style) (*((PDF::TextExtractor::Style*)style))
#define TEWCast(word) (*((PDF::TextExtractor::Word*)word))
#define TELCast(line) (*((PDF::TextExtractor::Line*)line))
#define PointCast(point) (*((PDF::Point*)point))
#define QPCast(qp) (*((PDF::QuadPoint*)qp))


//shared impl casts
#define FSCast(fs) ((SDF::Obj*)fs)
#define ActCast(act) ((SDF::Obj*)act)
#define PageCast(page) ((SDF::Obj*)page)
#define AnnCast(annot) ((SDF::Obj*)annot)
#define UStrCast(ustr) ((void*)ustr)
#define DestCast(dest) ((SDF::Obj*)dest)
#define PDFDcCast(pdfdc) ((PDF::PDFDC*)(pdfdc))
#define PDFDCEXCast(pdfdcex) ((PDF::PDFDCEX*)(pdfdcex))
#define PDocCast(pdoc) ((SDF::SDFDoc*)(pdoc))
#define RefCountedDocCast(pdoc) ((SDF::SDFDoc*)(pdoc))->GetSharedReference()
#define PDInfoCast(pdinfo) ((SDF::Obj*)(pdinfo))
#define PDFPrefCast(pdfpref) ((SDF::Obj*)(pdfpref))
#define BMCast(bm) ((SDF::Obj*)bm)
#define STreeCast(tree) ((SDF::Obj*)tree)
#define RMapCast(map) ((SDF::Obj*)map)
#define CMapCast(map) ((SDF::Obj*)map)
#define ImgCast(img) ((SDF::Obj*)img)
#define FDocCast(fdoc) ((SDF::SDFDoc*)fdoc)
#define RetUStr(str) { UString res(str); *result=(TRN_UString)res.mp_impl; res.mp_impl=0; }
// Copies a UString implementation (basic_string<Unicode>) and returns the pointer (to be managed by caller). Used by codegen.
TRN_UString ExtractTRNUStringCodegen(const trn::UString& in_ustring);

//return casts for direct cast objects
#define RetM2D(matrix) (*((TRN_Matrix2D*)&matrix))
#define RetField(field) (*((TRN_Field*)&field))
#define RetCI(item) (*((TRN_ContentItem*)&item))
#define RetSEle(element) (*((TRN_SElement*)&element))
#define RetPLbl(label) (*((TRN_PageLabel*)&label))
#define RetFField(field) (*((TRN_FDFField*)&field))

#define BEX try{
#define EEX } \
	catch(Common::Exception& e1) \
	{ \
		return GetPDFNetException(e1); \
	} \
	catch(std::exception& e2) \
	{ \
		std::string t(e2.what()); \
		return GetException(t); \
	} \
	catch(...) \
	{ \
		std::string t("An Unknown Exception Occurred\n"); \
		return GetException(t); \
	} \
	return 0;

#endif /* CEXCEPTION_HPP */
