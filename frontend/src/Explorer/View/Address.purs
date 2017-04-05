module Explorer.View.Address where

import Prelude
import Data.Array (length, (!!))
import Data.Lens ((^.))
import Data.Maybe (Maybe(..))
import Explorer.I18n.Lang (Language, translate)
import Explorer.I18n.Lenses (addNotFound, cAddress, common, cOf, cTransactions, address, addScan, addQrCode, addFinalBalance) as I18nL
import Explorer.Lenses.State (addressDetail, addressTxPagination, currentAddressSummary, lang, viewStates)
import Explorer.Types.Actions (Action(..))
import Explorer.Types.State (CCurrency(..), State)
import Explorer.Util.DOM (targetToHTMLInputElement)
import Explorer.View.Common (currencyCSSClass, emptyTxHeaderView, mkEmptyViewProps, mkTxBodyViewProps, mkTxHeaderViewProps, txBodyView, txPaginationView, txHeaderView)
import Network.RemoteData (RemoteData(..))
import Pos.Core.Lenses.Types (_Coin, getCoin)
import Pos.Explorer.Web.ClientTypes (CAddressSummary(..))
import Pos.Explorer.Web.Lenses.ClientTypes (_CAddress, caAddress, caBalance, caTxList, caTxNum)
import Pux.Html (Html, div, text, h3, p) as P
import Pux.Html.Attributes (className, dangerouslySetInnerHTML, id_) as P


addressView :: State -> P.Html Action
addressView state =
    let lang' = state ^. lang in
    P.div
        [ P.className "explorer-address" ]
        [ P.div
            [ P.className "explorer-address__wrapper" ]
            [ P.div
                  [ P.className "explorer-address__container" ]
                  [ P.h3
                          [ P.className "headline"]
                          [ P.text $ translate (I18nL.common <<< I18nL.cAddress) lang' ]
                  , addressOverview (state ^. currentAddressSummary) lang'
                  ]
            ]
            , P.div
                [ P.className "explorer-address__wrapper" ]
                [ P.div
                      [ P.className "explorer-address__container" ]
                      [ P.h3
                          [ P.className "headline"]
                          [ P.text $ translate (I18nL.common <<< I18nL.cTransactions) lang' ]
                        , case state ^. currentAddressSummary of
                              NotAsked  -> emptyTxHeaderView
                              Loading   -> emptyTxHeaderView
                              Failure _ -> emptyTxHeaderView
                              Success (CAddressSummary addressSummary) ->
                                  let txList = addressSummary ^. caTxList
                                      txPagination = state ^. (viewStates <<< addressDetail <<< addressTxPagination)
                                      currentTxBrief = txList !! (txPagination - 1)
                                  in
                                  P.div
                                      []
                                      [ txHeaderView lang' $ case currentTxBrief of
                                                                Nothing -> mkTxHeaderViewProps mkEmptyViewProps
                                                                Just txBrief -> mkTxHeaderViewProps txBrief
                                      , txBodyView $ case currentTxBrief of
                                                                  Nothing -> mkTxBodyViewProps mkEmptyViewProps
                                                                  Just txBrief -> mkTxBodyViewProps txBrief
                                      , txPaginationView
                                            { label: translate (I18nL.common <<< I18nL.cOf) $ lang'
                                            , currentPage: txPagination
                                            , maxPage: length txList
                                            , changePageAction: AddressPaginateTxs
                                            , onFocusAction: SelectInputText <<< targetToHTMLInputElement
                                            }
                                      ]

                      ]
                ]
            ]

-- | Address overview, we leave the error abstract (we are not using it)
addressOverview :: forall e. RemoteData e CAddressSummary -> Language -> P.Html Action
addressOverview NotAsked    lang = emptyAddressDetail ""
addressOverview Loading     lang = emptyAddressDetail "Loading..."
addressOverview (Failure _) lang = emptyAddressDetail $ translate (I18nL.address <<< I18nL.addNotFound) lang
addressOverview (Success addressSummary) lang =
    P.div
        []
        [ addressDetailView addressSummary lang
        , addressQr addressSummary lang
        ]

addressDetailView :: CAddressSummary -> Language -> P.Html Action
addressDetailView addressSummary lang =
    P.div
        [ P.className "address-detail" ]
        $ map addressDetailRow $ addressDetailRowItems addressSummary lang

addressQr :: CAddressSummary -> Language -> P.Html Action
addressQr _ lang =
    P.div
      [ P.className "qr" ]
      [ P.p
          [ P.className "tab" ]
          [ P.text $ translate (I18nL.address <<< I18nL.addQrCode) lang  ]
      , P.div
          [ P.className "qr__wrapper" ]
          [ P.div
              [ P.className "qr__image"
              , P.id_ "qr_image_id"
              ]
              []
            , P.p
                [ P.className "qr__description" ]
                [ P.text $ translate (I18nL.address <<< I18nL.addScan) lang ]
          ]
      ]

type SummaryRowItem =
    { label :: String
    , value :: String
    , currency :: Maybe CCurrency
    }

type SummaryItems = Array SummaryRowItem

addressDetailRowItems :: CAddressSummary -> Language -> SummaryItems
addressDetailRowItems (CAddressSummary address) lang =
    [ { label: translate (I18nL.common <<< I18nL.cAddress) lang
      , value: address ^. (caAddress <<< _CAddress)
      , currency: Nothing
    }
    , { label: translate (I18nL.common <<< I18nL.cTransactions) lang
      , value: show $ address ^. caTxNum
      , currency: Nothing
    }
    , { label: translate (I18nL.address <<< I18nL.addFinalBalance) lang
      , value: show $ address ^. (caBalance <<< _Coin <<< getCoin)
      , currency: Just ADA
      }
    ]

addressDetailRow :: SummaryRowItem -> P.Html Action
addressDetailRow item =
    P.div
        [ P.className "address-detail__row" ]
        [ P.div
            [ P.className "address-detail__column column label" ]
            [ P.text item.label ]
        , P.div
              [ P.className $ "address-detail__column amount" <> currencyCSSClass item.currency ]
              [ P.text item.value ]
        ]

emptyAddressDetail :: String -> P.Html Action
emptyAddressDetail message =
    P.div
        [ P.className "explorer-address__container" ]
        [ P.div
            [ P.dangerouslySetInnerHTML message ]
            []
        ]
