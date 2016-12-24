# 企画登録WebAPI

## WebAPI利用フロー

### 1． conkan programにadminとしてlogin

```
METHOD  : POST
URL     : <Conkan_Program_URL>/login
POSTDATA: [
            'realm'     => 'passwd',      // 固定値
            'account'   => 'admin',       // 固定値
            'passwd'    => ,              // 事前に共有
          ]
```

### 2. 企画情報を登録

```
METHOD  : POST
URL     : <Conkan_Program_URL>/program/add
POSTDATA: Content_Type => 'form-data',
          Content      =>
            [
                'jsoninputfile' =>
                    [
                        undef,
                        'regprog.json',
                        'Content-Type' => 'application/octet-stream',
                        'Content'      => <パラメータ>
                    ]
            ]
```

<パラメータ>は、下記 javascript Object をJSON化した値

```javascript
webAPI = {
    WebAPI_VERSION    :   '2.0',      // 固定値
    prog_no           :   ,           // 企画ID (基本的には未指定)
    p1_name           :   ,           // 申込者氏名
    email             :   ,           // 申込者メールアドレス
    reg_num           :   ,           // 申込者登録番号
    tel               :   ,           // 申込者電話番号
    fax               :   ,           // 申込者FAX番号
    cellphone         :   ,           // 申込者携帯番号
    pg_name           :   ,           // 企画名
    pg_name_f         :   ,           // 企画名フリガナ
    pg_kind           :   ,           // 企画種別(その他内容)
    pg_place          :   ,           // 希望場所(その他内容)
    pg_layout         :   ,           // 希望レイアウト(その他内容)
    pg_time           :   ,           // 希望時刻(その他内容
    pg_koma           :   ,           // 希望コマ数(その他内容)
    pg_ninzu          :   ,           // 予想人数
    pg_naiyou         :   ,           // 企画内容
    pg_naiyou_k       :   ,           // 内容事前公開
    pg_kiroku_kb      :   ,           // リアルタイム公開
    pg_kiroku_ka      :   ,           // 事後公開
    pg_pggen          :   ,           // 一般公開可否
    pg_pgu18          :   ,           // 未成年参加可否
    pg_badprog        :   ,           // 重なると困る企画
    pg_enquete        :   ,           // 企画経験
    fc_comment        :   ,           // 備考(連絡可能時間帯)
    equips            :               // 機材情報配列
    [
        {
            name              :   ,       // 機材名
            count             :   ,       // 本数
            vif               :   ,       // 映像接続
            aif               :   ,       // 音声接続
            eif               :   ,       // LAN接続
            intende           :   ,       // LAN利用目的
        },
    ],
    casts             :               // 出演者情報配列
    [
        {
            name              :   ,       // 出演者登録名
            entrantregno      :   ,       // 出演者登録番号
            pgname            :   ,       // 企画ネーム
            pgnamef           :   ,       // 企画ネームフリガナ
            pgtitle           :   ,       // 肩書
            needreq           :   ,       // 出演交渉
            needguest         :   ,       // ゲスト申請
        },
    ],
}
```

### 3. 登録POSTのRESPONCEから、内部企画IDと企画IDを取り出す

登録POSTのRESPONCEは

```
<a href="/program/{内部企画ID}&amp;prog_id={企画ID}">
```
なので、これを解析して企画IDを取り出す。(申込者の通知に利用)  
内部企画IDも取り出せるが、これはWebAPIでの登録時に意味はない。  
_JSONファイルをアップロードして登録する場合、登録した企画詳細画面にジャンプするために存在する_

### 4. logout

```
METHOD  : GET
URL     : <Conkan_Program_URL>/logout
```

## 開発用関係表
企画登録WebAPIのPOSTデータを作成し、Conkan ProgramのDBに登録するために必要な情報を、幾つかの表にまとめる。

### prog_regist上のParam名とその値の関係表

Param名         | 値
--------------- | -----------------------------------------------
p1_name         | 値自体 申込者氏名
email           | 値自体 申込者メールアドレス
reg_num         | 値自体 申込者登録番号
tel             | 値自体 申込者電話番号
fax             | 値自体 申込者FAX番号
cellphone       | 値自体 申込者携帯番号
pg_name         | 値自体 企画名
pg_name_f       | 値自体 企画名フリガナ
pg_kind         | pgregdef:@pg_kind_aryのVAL 企画種別
pg_kind2        | 値自体 企画種別その他内容
pg_place        | pgregdef:@pg_place_aryのVAL 希望場所
pg_place2       | 値自体 希望場所その他内容
pg_layout       | pgregdef:@pg_layout_aryのVAL 希望レイアウト
pg_layout2      | 値自体 希望レイアウトその他内容
pg_time         | pgregdef:@pg_time_aryのVAL 希望時刻
pg_time2        | 値自体 希望時刻その他内容
pg_koma         | pgregdef:@pg_koma_aryのVAL 希望コマ数
pg_koma2        | 値自体 希望コマ数その他内容
pg_ninzu        | pgregdef:@pg_ninzu_aryのVAL 予想人数
pg_naiyou       | 値自体 企画内容
pg_naiyou_k     | pgregdef:@pg_naiyou_k_aryのVAL 内容事前公開
pg_kiroku_kb    | pgregdef:@pg_kiroku_aryのVAL リアルタイム公開
pg_kiroku_ka    | pgregdef:@pg_kiroku_aryのVAL 事後公開
pg_pggen        | pgregdef:@pg_kafuka_aryのVAL 一般公開可否
pg_pgu18        | pgregdef:@pg_kafuka_aryのVAL 未成年参加可否
pg_badprog      | 値自体 重なると困る企画
pg_enquete      | pgregdef:@pg_enquete_aryのVAL 企画経験
fc_comment      | 値自体 備考
phonetime       | 値自体 連絡可能時間帯
                |
wbd             | 'on' 提供機材 ホワイトボード 使用
mon             | 'on' 提供機材 モニタ 使用
dvd             | 'on' 提供機材 DVD 使用
syo             | 'on' 提供機材 書画カメラ 使用
                |
fc_other_naiyou | 値自体 その他提供機材
fc_mochikomi    | 値自体 その他持ち込み機材
                |
mic             | 'on' 提供機材 壇上マイク 使用
miccnt          | 値自体 壇上マイク本数
mic2            | 'on' 提供機材 客席マイク 使用
miccnt2         | 値自体 客席マイク本数
                |
fc_vid          | pgregdef:@motikomi_aryのVAL 持ち込み映像機器
av-v            | pgregdef:@av_v_aryのVAL 映像機器映像接続
av-v_velse      | 値自体 映像機器映像接続その他内容
av-a            | pgregdef:@av_a_aryのVAL 映像機器音声接続
av-a_velse      | 値自体 映像機器音声接続その他内容
                |
fc_pc           | pgregdef:@motikomi_aryのVAL 持ち込みPC
pc-v            | pgregdef:@pc_v_aryのVAL PC映像接続
pc-v_velse      | 値自体 PC映像接続その他内容
pc-a            | pgregdef:@pc_a_aryのVAL PC音声接続
pc-a_velse      | 値自体 PC音声接続その他内容
lan             | pgregdef:@lan_aryのVAL PC LAN接続
pc-l_velse      | 値自体 PC LAN接続その他内容
lanreason       | 値自体 PC  LAN利用目的
                |
youdo           | pgregdef:@ppn_youdo_aryのVAL 申込者出演
py_name         | 値自体 申込者企画ネーム
py_name_f       | 値自体 申込者企画ネームフリガナ
py_title        | 値自体 申込者肩書
                |
pp_cnt          | 値自体 出演者数(申込者除く)
pp<n>_name      | 値自体 出演者名
pp<n>_name_f    | 値自体 出演者名フリガナ
pp<n>_title     | 値自体 出演者肩書
pp<n>_con       | pgregdef:@ppn_con_aryのVAL 出演交渉
pp<n>_grq       | pgregdef:@ppn_grq_aryのVAL ゲスト申請

### prog_regist上のParam名とWebAPI JSONキーの関係表

注: **prog_no**は原則としてAPIデータとしては指定せず、conkan_programで生成する  
    特殊な場合(_企画IDを指定したい場合_)のみ使用するが、そのユースケースは提供していない  
注: **regdate** は常にクライアント(ブラウザ)からではなく、prog_registで生成して設定する

Param名        | JSONキー             | 説明
-------------- | -------------------- | ---------------------------
               | WebAPI_VERSION       | WebAPIバージョン('2.0'固定)
               | **prog_no**          | 企画ID(原則未指定)
               | **regdate**          | 申込み日付
p1_name        | p1_name              | 申込者氏名
email          | email                | 申込者メールアドレス
reg_num        | reg_num              | 申込者登録番号
tel            | tel                  | 申込者電話番号
fax            | fax                  | 申込者FAX番号
cellphone      | cellphone            | 申込者携帯番号
pg_name        | pg_name              | 企画名
pg_name_f      | pg_name_f            | 企画名フリガナ
pg_kind        | pg_kind              | 企画種別(その他内容)
pg_place       | pg_place             | 希望場所(その他内容)
pg_layout      | pg_layout            | 希望レイアウト(その他内容)
pg_time        | pg_time              | 希望時刻(その他内容
pg_koma        | pg_koma              | 希望コマ数(その他内容)
pg_ninzu       | pg_ninzu             | 予想人数
pg_naiyou      | pg_naiyou            | 企画内容
pg_naiyou_k    | pg_naiyou_k          | 内容事前公開
pg_kiroku_kb   | pg_kiroku_kb         | リアルタイム公開
pg_kiroku_ka   | pg_kiroku_ka         | 事後公開
pg_pggen       | pg_pggen             | 一般公開可否
pg_pgu18       | pg_pgu18             | 未成年参加可否
pg_badprog     | pg_badprog           | 重なると困る企画
pg_enquete     | pg_enquete           | 企画経験
fc_comment     | fc_comment           | 備考(連絡可能時間帯)
               |                      |
               | equips[]             | 要望提供機材
               |     {                |
wbd mon dvd syo <br/> fc_other_naiyou fc_mochikomi | name  |    機材名
               |     }                |
               |                      |
               | equips[]             | 要望提供機材
               |     {                |
mic mic2       |         name         |    機材名
miccnt miccnt2 |         count        |    本数
               |     }                |
               |                      |
               | equips[]             | 要望提供機材
               |     {                |
fc_vid         |         name         |    機材名
av-v           |         vif          |    映像接続(その他内容)
av-a           |         aif          |    音声接続(その他内容)
               |     }                |
               |                      |
               | equips[]             | 要望提供機材
               |     {                |
fc_pc          |         name         |    機材名
pc-v           |         vif          |    映像接続(その他内容)
pc-a           |         aif          |    音声接続(その他内容)
lan            |         eif          |    LAN接続(その他内容)
lanreason      |         intende      |    LAN利用目的
               |     }                |
               |                      |
               | casts[]              | 出演者情報
               |     {                |
*p1_name       |         name         | 出演者登録名
*reg_num       |         entrantregno | 出演者登録番号
py_name        |         pgname       | 企画ネーム
py_name_f      |         pgnamef      | 企画ネームフリガナ
py_title       |         pgtitle      | 肩書
               |         needreq      | 出演交渉(固定値)
               |         needguest    | ゲスト申請(固定値)
               |     }                |
               |                      |
               | casts[]              | 出演者情報
               |     {                |
pp<n>_name     |         pgname       | 企画ネーム
pp<n>_name_f   |         pgnamef      | 企画ネームフリガナ
pp<n>_title    |         pgtitle      | 肩書
pp<n>_con      |         needreq      | 出演交渉
pp<n>_grq      |         needguest    | ゲスト申請
               |     }                |

### WebAPI JSONキーとDataBase登録先との関係表

注: **prog_no**は原則としてAPIデータとしては指定せず、conkan_programでPgRegProgram登録時に生成する(AutoIncriment)  
    特殊な場合(_企画IDを指定したい場合_)のみ使用するが、そのユースケースは提供していない  
    すでに登録済みの値を指定した場合、登録エラーとなる  
注: PgRegProgram以外で使用する _prog_no_ は、conkan_programで生成した値を意味する。(APIで指定された場合はその値)  
注: PgCastで使用する _pgid_ と _castid_ は、conkan_programで生成した値を意味する。(別表への登録時に生成)

JSONキー              | schema<br/> => column
--------------------- | ----------------------
                      | PgRegProgram
 **prog_no**          | => regpgid
 regdate              | => regdate
 p1_name              | => regname
 email                | => regma
 reg_num              | => regno
 tel                  | => telno
 fax                  | => faxno
 cellphone            | => celno
 pg_name              | => name
 pg_name_f            | => namef
 pg_kind              | => type
 pg_place             | => place
 pg_layout            | => layout
 pg_time              | => date
 pg_koma              | => classlen
 pg_ninzu             | => expmaxcnt
 pg_naiyou            | => content
 pg_naiyou_k          | => contentpub
 pg_kiroku_kb         | => realpub
 pg_kiroku_ka         | => afterpub
 pg_pggen             | => openpg
 pg_pgu18             | => restpg
 pg_badprog           | => avoiddup
 pg_enquete           | => experience
 fc_comment           | => comment
                      | 
                      | PgProgram
 _prog_no_            | => regpgid
 pg_name              | => name
                      |
                      | PgRegEquip
 _prog_no_            | => regpgid
 equips[].name        | => name
 equips[].count       | => count
 equips[].vif         | => vif
 equips[].aif         | => aif
 equips[].eif         | => eif
 equips[].intende     | => intende
                      |                       
                      | PgRegCast
 _prog_no_            | => regpgid
 casts[].entrantregno | => entrantregno
 casts[].pgname       | => name
 casts[].pgnamef      | => namef
 casts[].pgtitle      | => title
 casts[].needreq      | => needreq
 casts[].needguest    | => needguest
                      |                       
                      | PgAllCast
 casts[].name         | => name
 casts[].entrantregno | => regno
                      |                       
                      | PgAllCast
 casts[].pgname       | => name
 casts[].pgnamef      | => namef
                      |
                      | PgCast
 _pgid_               | => pgid
 _castid_             | => castid
 casts[].pgname       | => name
 casts[].pgnamef      | => namef
 casts[].pgtitle      | => title
 casts[].needreq      | => status

# 参考 WebAPI Ver 1.0

(Conkan Program 1.0.0のWebAPI)

Conkan Program 1.0.0では
- JSONキー WebAPI_VERSION が存在しない  
  これをもって、WebAPI Ver 1.0とみなす
- 深度1のオブジェクトJSONしか使っていない  
  ARRAYやオブジェクト参照はない
  
なお、Version 2.0.0 公開時には、Version 1.0への対応を停止する。  
(Version 1.2.x では、WebAPI 1.0 と 2.0 の両方に対応する)

Param名         |  JSONキー                 | schema <br/>=> column
--------------- | ------------------------- | ----------------------
                |                           | PgRegProgram
prog_no         | 企画ID                    | => regpgid
regdate         | 申込み日付                | => regdate
p1_name         | 申込者名                  | => regname
email           | メールアドレス            | => regma
reg_num         | 参加番号                  | => regno
tel             | 電話番号                  | => telno
fax             | FAX番号                   | => faxno
cellphone       | 携帯番号                  | => celno
pg_name         | 企画名                    | => name
pg_name_f       | 企画名フリガナ            | => namef
pg_kind         | 企画種別                  | => type
pg_kind2        | 企画種別その他内容        |    ↑
pg_place        | 希望場所                  | => place
pg_place2       | 希望場所その他内容        |    ↑
pg_layout       | 希望レイアウト            | => layout
pg_layout2      | 希望レイアウトその他内容  |    ↑
pg_time         | 希望時刻                  | => date
pg_time2        | 希望時刻その他内容        |    ↑
pg_koma         | 希望コマ数                | => classlen
pg_koma2        | 希望コマ数その他内容      |    ↑
pg_ninzu        | 予想人数                  | => expmaxcnt
pg_naiyou       | 企画内容                  | => content
pg_naiyou_k     | 内容事前公開              | => contentpub
pg_kiroku_kb    | リアルタイム公開          | => realpub
pg_kiroku_ka    | 事後公開                  | => afterpub
pg_pggen        | 一般公開可否              | => openpg
pg_pgu18        | 未成年参加可否            | => restpg
pg_badprog      | 重なると困る企画          | => avoiddup
pg_enquete      | 企画経験                  | => experience
fc_comment      | 備考                      | => comment
phonetime       |                           |    ↑
                |                           |
                |                           | PgRegEquip
_prog_no_       | _企画ID_                  | => regpgid
wbd             | ホワイトボード            | => name
                |                           |
                |                           | PgRegEquip
_prog_no_       | _企画ID_                  | => regpgid
mic             | 壇上マイク                | => name
miccnt          | 壇上マイク本数            | => count
                |                           |
                |                           | PgRegEquip
_prog_no_       | _企画ID_                  | => regpgid
mic2            | 客席マイク                | => name
mic2cnt         | 客席マイク本数            | => count
                |                           |
                |                           | PgRegEquip
_prog_no_       | _企画ID_                  | => regpgid
mon             | モニタ/スクリーン         | => name
                |                           |
                |                           | PgRegEquip
_prog_no_       | _企画ID_                  | => regpgid
dvd             | BD/DVDプレイヤー          | => name
                |                           |
                |                           | PgRegEquip
_prog_no_       | _企画ID_                  | => regpgid
syo             | 書画カメラ                | => name
                |                           |
                |                           | PgRegEquip
_prog_no_       | _企画ID_                  | => regpgid
fc_other_naiyou | その他要望機材            | => name
                |                           |
                |                           | PgRegEquip
_prog_no_       | _企画ID_                  | => regpgid
fc_vid          | 持ち込み映像機器          | => name
av-v            | 映像機器映像接続          | => vif
av-v_velse      | 映像機器映像接続その他内容|    ↑
av-a            | 映像機器音声接続          | => aif
av-a_velse      | 映像機器音声接続その他内容|    ↑
                |                           |
                |                           | PgRegEquip
_prog_no_       | _企画ID_                  | => regpgid
fc_pc           | 持ち込みPC                | => name
pc-v            | PC映像接続                | => vif
pc-v_velse      | PC映像接続その他内容      |    ↑
pc-a            | PC音声接続                | => aif
pc-a_velse      | PC音声接続その他内容      |    ↑
lan             | PC-LAN接続                | => eif
pc-l_velse      | PC-LAN接続その他内容      |    ↑
lanreason       | LAN利用目的               | => intende
                |                           |
                |                           | PgRegEquip
_prog_no_       | _企画ID_                  | => regpgid
fc_mochikomi    | その他持ち込み機材        | => name
                |                           |
                |                           | PgRegCast
_prog_no_       | _企画ID_                  | => regpgid
youdo           | 申込者出演                |
_p1_name_       | _申込者名_                |
_reg_num_       | _参加番号_                | => entrantregno
py_name         | 出演者氏名1               | => name
py_name_f       | 出演者氏名ふりがな1       | => namef
py_title        | 出演者肩書1               | => title
                | 出演交渉1                 | => needreq
                | ゲスト申請1               | => needguest
                |                           |
                |                           | PgRegCast
_prog_no_       | _企画ID_                  | => regpgid
pp<n>_name      | 出演者氏名<n>             | => name
pp<n>_name_f    | 出演者氏名ふりがな<n>     | => namef
pp<n>_title     | 出演者肩書<n>             | => title
pp<n>_con       | 出演交渉<n>               | => needreq
pp<n>_grq       | ゲスト申請<n>             | => needguest

EOF
