//資料讀取
import delimited "G:\我的雲端硬碟\NTU\農價\month_data_org.csv", encoding(UTF-8) clear 

//處理時間格式使stata可讀取
gen year_month = date(date,"YM") 
format year_month %tdCCYY-NN 
gen y_m = mofd(year_month) 
format y_m %tm

//設定時間
tsset y_m
//畫趨勢圖
tsline price
//price取log
gen lnp = log(price)
//常態檢定-JB
jb price

//DF檢定
dfuller lnp if train ==0,trend reg       //檢定趨勢
dfuller lnp if train ==0 ,reg           //檢定常數項
dfuller lnp if train ==0,noconstant reg  //檢定無常數項及趨勢時的單根
dfgls lnp if train ==0,maxlag(4)

//取一階差分
gen lag1lnp = l.lnp //
gen newlnp = lag1lnp-lnp //

//一階差分做DF檢定
dfuller newlnp if train ==0,trend reg
dfuller newlnp if train ==0,reg
dfuller newlnp if train ==0,noconstant reg
dfgls newlnp if train ==0,maxlag(4)

//graph drop newlnac  // <---
//graph drop newlnpac // <---  此二句為刪除底下命名的graph時使用

//ACF、PACF
ac newlnp if train ==0, name(newlnac)            //ACF圖
pac newlnp if train ==0,name(newlnpac)           //PACF圖
graph combine newlnac newlnpac,note("95% C.I.")  //合併

//比較各ARIMA模型及其AIC、BIC
arima newlnp if train ==0,arima(4,0,2)   
estat ic
arima newlnp if train ==0,arima(5,0,2)
estat ic
arima newlnp if train ==0,arima(6,0,2)
estat ic
arima newlnp if train ==0,arima(4,0,1)
estat ic
arima newlnp if train ==0,arima(5,0,1)
estat ic
arima newlnp if train ==0,arima(6,0,1)
estat ic
arima newlnp if train ==0,arima(1,0,1)
estat ic
arima newlnp if train ==0,arima(0,0,2) //最佳模型
estat ic

//將總資料分成樣本內外
gen train_true = newlnp if train == 0 //樣本內
gen test_true = newlnp if train == 1 //樣本外
//跑模型
arima train_true,arima(0,0,2)
//取得總預測值
predict y_hat
//取得殘差
predict e,r
//對殘差檢定是否有白噪音--WN檢定
wntestq e
//畫總預測值與實際值比較圖
tsline train_true test_true y_hat

//將總預測值還原成原始ln(price)形式並分成樣本內外預測值
gen prelnp_train =lag1lnp- y_hat  if train == 0 //樣本內
gen prelnp_test  =lag1lnp- y_hat  if train == 1 //樣本外
//將真實值ln(price)分成樣本內外
gen train_lnp  = lnp if train == 0 //樣本內
gen test_lnp = lnp if train == 1 //樣本外
//畫ln(price)之樣本內外真實及預測比較圖
tsline train_lnp test_lnp  prelnp_train prelnp_test 

//算MSE、RMSE
gen train_mse= (train_lnp- prelnp_train)^2
sum train_mse  // 樣本內預測MSE(mean為MSE)
gen test_mse= (test_lnp- prelnp_test)^2
sum test_mse   // 樣本外預測MSE(mean為MSE)
egen train_mse_mean = mean(train_mse)
gen train_rmse= train_mse_mean^0.5
sum train_rmse // 樣本內預測RMSE(所有數字皆為RMSE)
egen test_mse_mean = mean(test_mse)
gen test_rmse= test_mse_mean^0.5
sum test_rmse  // 樣本外預測RMSE(所有數字皆為RMSE)

//test MSE: 0.0942788 
//test RMSE: 0.3070485
//train MSE: 0.1108279 
//train RMSE: 0.3329083



//add volumn

//比較各ARIMA模型及其AIC、BIC
arima newlnp volumn if train ==0,arima(4,0,2)   
estat ic
arima newlnp volumn if train ==0,arima(5,0,2)
estat ic
arima newlnp volumn if train ==0,arima(6,0,2)
estat ic
arima newlnp volumn if train ==0,arima(4,0,1)
estat ic
arima newlnp volumn if train ==0,arima(5,0,1)
estat ic
arima newlnp volumn if train ==0,arima(6,0,1)
estat ic
arima newlnp volumn if train ==0,arima(1,0,1)
estat ic
arima newlnp volumn if train ==0,arima(0,0,2) //加入volumn依然為最佳模型
estat ic

//將總資料分成樣本內外
gen v_train_true = newlnp if train == 0 //樣本內
gen v_test_true = newlnp if train == 1 //樣本外
//跑模型
arima v_train_true volumn,arima(0,0,2)
//取得總預測值
predict v_y_hat
//取得殘差
predict v_e,r
//對殘差檢定是否有白噪音--WN檢定
wntestq v_e
//畫總預測值與實際值比較圖
tsline v_train_true v_test_true v_y_hat

//將總預測值還原成原始ln(price)形式並分成樣本內外預測值
gen v_prelnp_train =lag1lnp- v_y_hat  if train == 0 //樣本內
gen v_prelnp_test  =lag1lnp- v_y_hat  if train == 1 //樣本外
//將真實值ln(price)分成樣本內外
gen v_train_lnp  = lnp if train == 0 //樣本內
gen v_test_lnp = lnp if train == 1 //樣本外
//畫ln(price)之樣本內外真實及預測比較圖
tsline v_train_lnp v_test_lnp  v_prelnp_train v_prelnp_test 

//算MSE、RMSE
gen v_train_mse= (v_train_lnp- v_prelnp_train)^2
sum v_train_mse  // 樣本內預測MSE(mean為MSE)
gen v_test_mse= (v_test_lnp- v_prelnp_test)^2
sum v_test_mse   // 樣本外預測MSE(mean為MSE)
egen v_train_mse_mean = mean(v_train_mse)
gen v_train_rmse= v_train_mse_mean^0.5
sum v_train_rmse // 樣本內預測RMSE(所有數字皆為RMSE)
egen v_test_mse_mean = mean(v_test_mse)
gen v_test_rmse= v_test_mse_mean^0.5
sum v_test_rmse  // 樣本外預測RMSE(所有數字皆為RMSE)

//v_test MSE: 0.0917578 
//v_test RMSE: 0.3029155
//v_train MSE: 0.1087181 
//v_train RMSE: 0.3297243