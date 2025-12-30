unit UConst;

interface

type
  // Open Types for links to external sites:
  TExternalOpenType = ( // Source
                        cOTNONE = 0,        // None selected yet
                        cOTREBRICKABLE = 1, // Parts and sets
                        cOTBRICKLINK = 2,   //
                        cOTBRICKOWL = 3,    //
                        cOTBRICKSET = 4,    // Sets
                        cOTLDRAW = 5,       // Parts
                        cOTCUSTOM = 6       // Parts and sets (probably)
                      );

  // Doubleclick action windows
  TDoubleClickActionType = ( cACTIONSEARCH = 0,
                             cACTIONCOLLECTION = 1,
                             cACTIONSETLIST = 2,
                             cACTIONPARTS = 3      // Only view parts, not edit parts.
                           );

  TDoubleClickAction = ( caVIEW = 0,
                         caVIEWEXTERNAL = 1,
                         caEDITDETAILS = 2,
                         caVIEWPARTS = 3,
                         caEDITPARTS = 4
                       );

  //View External types:
  TViewExternalType = ( cTYPESET = 0,
                        cTYPEPART = 1,
                        cTYPEMINIFIG = 2 // Not used yet
                      );

  //Config sections - used for saving specific sections instead of "everything"
  TConfigSection = (  csALL = 0,
                      csCONFIGDIALOG = 1,
                      csWINDOWPOSITIONS = 2,
                      csPARTSWINDOWFILTERS = 3,
                      csSEARCHWINDOWFILTERS = 4
                    );

  //Search what / View External types:
  TSearchWhat = ( cSEARCHTYPESET = 0,
                  cSEARCHTYPEPART = 1,
                  cSEARCHTYPEMINIFIG = 2    // Not used yet
                );

  TSearchBy = ( //cNUMBERORNAME = 0,
                cNUMBER = 0,
                cNAME = 2
              );

  TSearchStyle = ( // Search style for others
                   cSEARCHALL = 0,        // "%SearchText%" // May find a lot more unrelated stuff
                   // Search style for sets
                   cSEARCHPREFIX = 1,     // "SearchText%" // Also gets all versions// Search style for sets:
                   cSEARCHSUFFIX = 2,     // "%SearchText" and "%Searchtext-1" // Find parts of sets
                   cSEARCHEXACT = 3       // "SearchText"
                 );

  TExternalTypeFilters = ( cETFALL = 0,
                           cETFLOCAL = 1,       // So, not actually external
                           cETFREBRICKABLE = 2, // Imported from Rebrickable
                           cETFHASSETS = 3,
                           cETFNOSETS = 4
                         );

  TSetListCollectionColumns = ( colNAME = 0,
                                colSETS = 1,
                                colUSEINBUILD = 2,
                                colSORTINDEX = 3
                              );

  TCellAction = (   caNone = 0,
                    caLeftClick = 1,
                    caDoubleClick = 2,
                    caRightClick = 3);

  TSetListFilter = ( fltALL = 0,
                     fltQUANTITY = 1,
                     fltBUILT = 2,
                     fltNOTBUILT = 3,
                     fltSPAREPARTS = 4,
                     fltNOSPAREPARTS = 5
                   );

  TSetListColumn = ( slcolNAME = 0,
                     slcolBSID = 1,
                     slcolSETNUM = 2,
                     slcolQTY = 3,
                     slcolBUILD = 4,
                     slcolSPARES = 5,
                     slcolNOTE = 6
                   );

implementation

end.
