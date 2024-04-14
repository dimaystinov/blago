// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.6;

/* 

  88888888     88               8           8888         8888      8888888          8         88888888
  88     88    88              888         88  88       88  88     88    88        888        88     88
  88      88   88             .8888.      88    88     88    88    88     88      .8888.      88      88
  88     88    88             88  88     88           88      88   88      88     88  88      88     88
  88888888     88            .88  88.    88   88888   88      88   88      88    .88  88.     88888889
  88     88    88            88    88    88      88   88      88   88      88    88    88     88   88 
  88      88   88           .88888888.    88    88     88    88    88     88    .88888888.    88    88
  88     88    88           88      88     88  88       88  88     88    88     88      88    88     88
  88888888     8888888888  .88      88.     8888         8888      8888888     .88      88.   88      88         

*/

contract BLAGODAR {

    string public constant standard = 'BLAGODAR ZRC20';                 // Название стандарта контракта
    string public constant name = 'BLAGODAR';                          // Название токена
    string public constant symbol = 'DAR';                            // Символ токена
    uint256 public constant decimals = 8;                               
    uint256 public constant ZHC = 10 ** decimals;                       // Одно ЗХ
    uint256 public constant DAY = 24 * 60 * 60;              // Время дня в секундах для генерации платежки
    uint256 public constant week = 7;                                   // Неделя уровня
    
    uint256 public constant totalSupply = 10 * (10 ** 9) * ZHC;
    uint256 public first_user_ballance = 100 * 10 ** 6 * ZHC;
    uint256 public constant one_payment =  1 * ZHC;
    address public owner;
    
    uint256 random_counter = 1; 
    address [] public all_users;
    address public usdt_contract = 0xA48d0eE7365cE1adD8e595De4d54344239F8CA28;
    address [] public all_admins;
    mapping (address => bool) public is_admin;
    bool public prestart = true;
    uint256 public current_day = 10;

    uint256 public max_array_len = 500; 
    uint256 public constant section_payment_len = 10;
    uint256 public day_start = current_day;     

    uint256 public time_start = block.timestamp -  block.timestamp % DAY;   // Время от начала дня старта
    uint256 public time_new_day = time_start;


    address [] public users_with_node;

    mapping (address => bool [2]) public forging_node;                      // Регистрация, форжинг
    uint256 public pre_pool_len = 0;
    
    mapping (address => uint256) public balanceOf;
    mapping (address => mapping (address => uint256)) public allowance;

    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
    event Received(address, uint256);

    uint256 constant forge_node_procent = 20;
    uint256 constant level_numbers = 12;

    uint256 [level_numbers] public coefs = [2,3,6,7,8,9,10,11,12,13,14,15] ; // level 0-11 проценты
    uint256 quant_limit = 100 * ZHC;
    uint256 [level_numbers] public withdraw_limits = [quant_limit, quant_limit, quant_limit,quant_limit, 2 * quant_limit, 3 * quant_limit, 4 * quant_limit, 5 * quant_limit, 7 * quant_limit, 11 * quant_limit, 11 * quant_limit ];
     
    uint256 public full_amount;

    uint256 public application_number = 0;
    uint256 public lower_bound_random_day = 5; 
    uint256 public upper_bound_random_day = 10; 
    uint256 public last_pool_i = 0;

    mapping (address => User) public user;
    mapping(uint256 => Payment) public payment_application;
    mapping (uint256 => uint256) public pre_pool;
    mapping (address => uint256) public the_amount_of_accepted_gifts;

    address public constant first_user = 0x2051fb57B0E7dFce110189df1D9F455af30e81B4;    // ZEz9c2EsheXnkZCMqcwjA2m2ZwKYs641Lq 
    address public constant multiplicator = 0xD21DFDf264b6f1588C2F129F86FD27331Ba41928; // ZXCFbrLgKxN3i48VBmQ8kEQsqKjWR3JhCC
    address public constant admin = 0x632d3353F5aB6Ce87f49c35100bAc92828F244Aa;         // ZM5epGK5bJnRvK2VBfupVB4PHETzR2GLH8  

    struct User{ 
           
        bool is_registered;             // Статус регистрации
        bool is_forging;                // Статус есть ли форжащая нода
        uint256 level;                  // Уровень
        address referer;                // Пригласивший
        address wallet_for_work;        // Кошелек для принятия благодарности
        uint256 lost_referal_funds;     // Потерянные реферальные средства
        address forging_node;           // Зарегистрированная нода
        bool isWithdraw;                // Флаг активации на вывод
        uint256 active;                 // Активность 
        uint256 last_update_timestamp;  // Последнее время совершения или получения благодарности
        uint256 all_payments_len;       // Количество всех платёжек
        uint256 all_withdraw_payments_len; // Все оплаченные платёжки
        uint256 referrals_len;          // Число рефералов
        uint256 registration_day;
        address [] add_wallets;         // Дополнительные кошельки
        uint256 [level_numbers] referral_level_number; // Число рефералов по уровням

        mapping (uint256 => address) referrals;                             // Рефералы
        mapping (uint256 => uint256) all_payments;                          // Все платёжки
        mapping (uint256 => uint256) all_withdraw_payments;                 // Все оплаченные платёжки
        mapping (uint256 => uint256 [] ) tranz_withdraw_in_day;             // Все оплаченные платёжки по дням
        mapping (uint256 => address []) referrals_invited_by_day;           // Рефералы приглашенные по дням
        mapping (uint256 => bool [3])  recalculation_of_level_and_active_day; // Обновление уровня, активности и отзыв  0 [0, была ли учтена активность реферера, 0]
        mapping (address => uint256) add_wallet_level;                      // Уровень доп кошеля
        mapping (address => mapping(uint256 => uint256 []) ) tranz_in_day;  // Все транзы доп кошелей по дням
        mapping (address => uint256) change_level_day;                      // День изменения уровня
        mapping (address => uint256 [2]) hyper_jump_level;                      // Уровень гиперпрыжка для доп кошелей, день изменения
        
    }

    struct Payment {
        address user_wallet;            // Горячий, зарегестрированный в системе, кошелек пользователя
        address wallet_for_withdraw;    // Кошелек для вывода. Текущий wallet_for_work юзера
        uint256 reward_time;            // Время для выплаты =(Время создания запроса помощи + период созревания)
        uint256 payment_time;           // Время создания запроса помощи
        uint256 amount;                 // Количество токенов запроса помощи
        uint256 amount_for_withdraw;    // Количество токенов вознаграждения
        bool fallacy;                   // Ошибочность транзакции
        bool isRepaid;                  // Статус выплаты
        uint256 balance;                // Баланс на момент создания транзакции
    }


    constructor () { 
        user[multiplicator].is_registered = false; 
        user[first_user].is_registered = true;
        user[first_user].registration_day = current_day;
        user[first_user].level = 10;
        user[first_user].referer = first_user;
        all_users.push(first_user);

        all_admins.push(msg.sender);
        all_admins.push(admin);  
        all_admins.push(first_user); 

        is_admin[msg.sender] = true;
        is_admin[admin] = true;
        is_admin[first_user] = true;

        owner = msg.sender;

        balanceOf[msg.sender] = totalSupply - 12 * first_user_ballance;
        emit Transfer(address(0), msg.sender, totalSupply - 12 * first_user_ballance);

        balanceOf[first_user] = first_user_ballance; 
        emit Transfer(address(0), first_user, first_user_ballance);

        balanceOf[multiplicator] = first_user_ballance; 
        emit Transfer(address(0), multiplicator, first_user_ballance);

        balanceOf[address(this)] = 10 * first_user_ballance; 
        emit Transfer(address(0), address(this),  10 * first_user_ballance); 

    }

    modifier validAddress(address _address) {
        require(_address != address(0));
        _;
    }
    modifier onlyAdmin(address _address) {
        require(is_admin[msg.sender],"You are not an admin"); 
        _;
    }



    


    

    function get_the_current_day() public view returns (uint256){
        return  current_day; 
    }

    function check_new_day() public{

        if (block.timestamp - time_new_day >= DAY){
            current_day = 10 + (block.timestamp - time_start) / (DAY);
            last_pool_i = 0;
            time_new_day = block.timestamp - block.timestamp % DAY;
        }
    }

   
    
    function admin_node_registrate(address node, address user_address) onlyAdmin(msg.sender) public{
        require(forging_node[node][0] == true ,"You don't send ZHC to contract");
        require(forging_node[node][1] == false,"Node already registered"); 
        forging_node[node][1] == true;
        user[user_address].forging_node = node; 
        users_with_node.push(user_address);
    }
    

    function is_address_in_add_wallets(address user_address, address wallet) public view returns(bool){
        for (uint256 i = 0; i < user[user_address].add_wallets.length; i++){
            if (user[user_address].add_wallets[i] == wallet){
                return true;
            }
        }
        return false;
    }

    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }


    function get_user_referrals(address user_address, uint256 start_number, uint256 finish_number) public view returns(address [] memory ){ //address user_address,
        require(start_number <= finish_number);
        finish_number = min(user[user_address].referrals_len, start_number + max_array_len); 
        address [] memory user_referrals = new address [](finish_number - start_number);
        for(uint256 i = start_number; i < finish_number; i++){
            user_referrals[i - start_number] = user[user_address].referrals[i]; 
        }
        return user_referrals;
    } 

    function get_user_payments(address user_address, uint256 start_number, uint256 finish_number) public view returns(uint256 [] memory ){
        require(start_number <= finish_number);
        finish_number = min(user[user_address].all_payments_len, start_number + max_array_len);
        uint256 [] memory user_payments = new uint256 [](finish_number - start_number);
        for(uint256 i = start_number; i < finish_number; i++){
            user_payments[i - start_number] = user[user_address].all_payments[i];
        }
        return user_payments;   
    }

     function get_user_all_withdraw_payments(address user_address, uint256 start_number, uint256 finish_number) public view returns(uint256 [] memory ){
        require(start_number <= finish_number);
        finish_number = min(user[user_address].all_withdraw_payments_len, start_number + max_array_len); 
        uint256 [] memory user_referrals = new uint256 [](finish_number - start_number);
        for(uint256 i = start_number; i < finish_number; i++){
            user_referrals[i - start_number] = user[user_address].all_withdraw_payments[i];//user[user_address].referrals[i]; 
        }
        return user_referrals;
    }


    function get_user_add_wallets(address user_address) public view returns(address [] memory ){
        return user[user_address].add_wallets;
    }

    function get_user_referral_level_number(address user_address) public view returns (uint256 [level_numbers] memory ){
        return user[user_address].referral_level_number;
    }
    function get_user_add_wallet_level(address user_address, address add_wallet) public view returns(uint256 ){
        return user[user_address].add_wallet_level[add_wallet];  
    }

    function get_user_add_wallet_tranz_in_day(address user_address, address add_wallet, uint256 day) public view returns(uint256 [] memory){
        return user[user_address].tranz_in_day[add_wallet][day]; 
    }
    function get_user_add_wallet_tranz_in_day_length(address user_address, address add_wallet, uint256 day) public view returns(uint256){
        return user[user_address].tranz_in_day[add_wallet][day].length; 
    } 
    
    function get_user_add_wallet_tranz_withdraw_in_day(address user_address, uint256 day) public view returns(uint256 [] memory){
        return user[user_address].tranz_withdraw_in_day[day]; 
    }
    function get_user_add_wallet_tranz_withdraw_in_day_length(address user_address, uint256 day) public view returns(uint256){
        return user[user_address].tranz_withdraw_in_day[day].length; 
    } 

    function get_user_add_wallet_change_level_day(address user_address, address add_wallet) public view returns(uint256 ){
        return user[user_address].change_level_day[add_wallet]; 
    }

    function get_user_add_wallet_hyper_jump_level(address user_address, address add_wallet) public view returns(uint256 [2] memory ){
        return user[user_address].hyper_jump_level[add_wallet];  
    }
    

    function get_user_referrals_by_day(address user_address, uint256 day) public view returns(address [] memory ){
        return user[user_address].referrals_invited_by_day[day];
    }

    function get_user_calculation_level_and_active(address user_address, uint256 day) public view returns(bool [3] memory ){ // and feedback day
        return user[user_address].recalculation_of_level_and_active_day[day];
    }
 
    function get_all_users_len() public view returns (uint256) {
        return all_users.length;
    }

    function admin_user_send_feedback(address user_address, uint256 day, uint256 status) onlyAdmin(msg.sender) public {
        if (status != 0) {
            user[user_address].recalculation_of_level_and_active_day[day][2] = true;
        }
        else user[user_address].recalculation_of_level_and_active_day[day][2] = false;
    }


    function set_max_wallet_level(address user_address) public { 
            uint256 max_level = 0;
            uint256 old_user_level = user[user_address].level;
            for (uint256 i = 0; i < user[user_address].add_wallets.length; i++){
            if (  user[user_address].add_wallet_level[user[user_address].add_wallets[i]] > max_level){
                max_level = user[user_address].add_wallet_level[user[user_address].add_wallets[i]];
            }
        }

        if (user[user_address].level != max_level){
            address user_referer = user[user_address].referer;
            if (user[user_referer].referral_level_number[old_user_level] > 0) user[user_referer].referral_level_number[old_user_level] -= 1;
            user[user_referer].referral_level_number[max_level] += 1; 
            user[user_address].level = max_level;
        }
        
    }

    
    function is_user_did_feedback_last_week(address user_address, uint256 test_current_day) public view returns(uint256) {
        uint256 day = test_current_day; 
        for (day; day >= current_day - 7; day--){
            if (user[user_address].recalculation_of_level_and_active_day[day][2] == true)
                return day; 
        }
        return 0;    
    }
    
    function change_wallet_level (address user_address) public {

        if (!user[user_address].recalculation_of_level_and_active_day[current_day][0]) {
            // calculate_active_referrals(user_address, current_day);
            user[user_address].recalculation_of_level_and_active_day[current_day][0] = true; 
            for (uint256 i = 0; i < user[user_address].add_wallets.length; i++){
                change_add_wallet_level(user_address, user[user_address].add_wallets[i]);
            }
            set_max_wallet_level(user_address);
            add_active_to_referer(user_address);
        }
    }


    function change_add_wallet_level(address user_address, address add_wallet) public{
        
        uint256 current_level = user[user_address].add_wallet_level[add_wallet];

            if (user[user_address].tranz_in_day[add_wallet][current_day - 1].length < 5){
                    user[user_address].add_wallet_level[add_wallet] = 0;
                    user[user_address].change_level_day[add_wallet] = current_day;
                    return; 
                }

            if (user[user_address].add_wallet_level[add_wallet] > 1 ){
                    if (!check_conditions_next_level(user_address,  user[user_address].add_wallet_level[add_wallet] - 1)){
                    user[user_address].add_wallet_level[add_wallet] = 1;
                    user[user_address].change_level_day[add_wallet] = current_day;
                    return; 
                    }
            }
                        
            if ( ((current_day - user[user_address].change_level_day[add_wallet]) >= week && is_user_did_feedback_last_week(user_address, current_day) > 0 || current_level == 0)  ) { // change to 7
                if (user[user_address].hyper_jump_level[add_wallet][0] != 0 && current_level >= 1){
                    user[user_address].add_wallet_level[add_wallet] = user[user_address].hyper_jump_level[add_wallet][0];
                    user[user_address].hyper_jump_level[add_wallet][0] = 0;
                    user[user_address].hyper_jump_level[add_wallet][1] = 0;
                    user[user_address].change_level_day[add_wallet] = current_day;
                    return;
                }
                if (check_conditions_next_level(user_address, current_level)){
                    user[user_address].add_wallet_level[add_wallet] += 1;
                    user[user_address].change_level_day[add_wallet] = current_day;
                    return ; 
                }
                          
            }  

            
        return; 
         
    }
    function check_conditions_next_level(address user_address, uint256 current_level) public view  returns (bool){
        
        if (current_level == 0){
            return true;
        }
        uint256 i = 0;
        if (current_level <= 3 && current_level >= 1){
            uint256 excepted_referrals = 0;
            for (i = 1; i < level_numbers; i++){

                excepted_referrals += user[user_address].referral_level_number[i];

                if (excepted_referrals >= current_level + 1){
                    return true;
                }
            }
            return false;
        }

        if (current_level == 4){
            uint256 excepted_referrals = 0;
            bool referal_2_level = false;
            for (i = 1; i < level_numbers; i++){

                excepted_referrals += user[user_address].referral_level_number[i];

                if (i >= 2 && user[user_address].referral_level_number[i] > 0 ){
                    referal_2_level = true;
                }

                if (referal_2_level && excepted_referrals >= 5 ){
                    return true;
                }
            }
            return false;
        }

        if (current_level == 5){
            uint256 excepted_referrals = 0;
            for (i = 2; i < level_numbers; i++){
                
                excepted_referrals += user[user_address].referral_level_number[i];
                
                if (excepted_referrals >= current_level + 1){
                    return true;
                }   
            }
            return false;
        }

        if (current_level >= 6 && current_level <= 10){
            uint256 excepted_referrals = 0;
            for (i = current_level - 1; i < level_numbers; i++){

                excepted_referrals += user[user_address].referral_level_number[i];

                if (excepted_referrals >= current_level + 1){
                    return true;
                } 
            }
            return false;
        }
        return false;

    }

    function admin_dice_roll_level(address user_address,  uint256 level) onlyAdmin(msg.sender) public{
        if (level < 1) return;
        require(balanceOf[user_address] >= 10 * ZHC, "Your balance less 10 tokens");
        address add_wallet = user[user_address].wallet_for_work;
        require(level <= 5 && level > 1,"level should be less or equal 6 and more 0"); 
        require(user[user_address].tranz_in_day[add_wallet][current_day - 1].length >= 5 && user[user_address].tranz_in_day[add_wallet][current_day].length >= 5,"You didn't make 5 transactions yesterday and today" );

        if (_transfer(user_address, multiplicator, 10 * ZHC)){
                user[user_address].hyper_jump_level[add_wallet][0] = level; 
                user[user_address].hyper_jump_level[add_wallet][1] = current_day;  
        }
        
    }

    function add_active_to_referer(address user_address) internal {
        if (user[user_address].recalculation_of_level_and_active_day[0][1]) return;
            if( !user[user_address].recalculation_of_level_and_active_day[0][0]){
                if (current_day - user[user_address].registration_day < 5 && user[user_address].level > 0){
                    user[user[user_address].referer].active += 1;
                    user[user_address].recalculation_of_level_and_active_day[0][0] = true;
                }
            }
            else {
                if (current_day - user[user_address].registration_day >= 5){
                    user[user[user_address].referer].active -= 1;
                    user[user_address].recalculation_of_level_and_active_day[0][1] = true;
            }   
    }
    }

    function admin_registrate(address referer_address, address user_address) onlyAdmin(msg.sender) public {
        require(user_address != multiplicator && user_address != first_user && user_address != address(0) && user_address != address(this) && referer_address != address(0));
        require(forging_node[user_address][0] == false, "Node is already registered in smartcontract");
        require(user[user_address].is_registered == false);
        if ( !prestart){
            require(user[referer_address].is_registered == true, "Prestart is ower");
        }
        user[user_address].is_registered = true;
        user[user_address].registration_day = current_day;
        user[user_address].wallet_for_work = user_address;
        user[user_address].referer = referer_address;
        user[referer_address].referral_level_number[0] += 1; 
        user[referer_address].referrals[user[referer_address].referrals_len] = user_address;
        user[referer_address].referrals_len++;
        if (user[referer_address].referrals_invited_by_day[current_day].length < max_array_len){
            user[referer_address].referrals_invited_by_day[current_day].push(user_address);
        }
        all_users.push(user_address); 
        user[user_address].add_wallets.push(user_address);
    }

    function admin_change_is_withdraw(address _user_address, uint256 _is) onlyAdmin(msg.sender) public {
        if (_is == 0){ 
            user[_user_address].isWithdraw = false;
        }
        else {
            user[_user_address].isWithdraw = true;
        }
    }

    function admin_node_is_forging(address _user_address, uint256 _is) onlyAdmin(msg.sender) public {
        require(user[_user_address].forging_node != address(0));
        if (_is == 0){ 
            user[_user_address].is_forging = false;
        }
        else {
            user[_user_address].is_forging = true;
        }
    }


    function admin_registrate_add_wallet(address user_address, address add_wallet) onlyAdmin(msg.sender) public {
        require(user[user_address].is_registered == true, "User is not registered");
        require(user[user_address].add_wallets.length <= 4,"You can't register more than 3 add wallets");  
        require(is_address_in_add_wallets(user_address, add_wallet) == false, "You already registrate this add wallet");  
        user[user_address].add_wallets.push(add_wallet);
        
    }
    function admin_change_wallet_for_work(address user_address, address add_wallet) onlyAdmin(msg.sender) public {
        require(user[user_address].is_registered == true, "User is not registered"); 
        require(is_address_in_add_wallets(user_address, add_wallet),"Wallet not in additional wallets");
        user[user_address].wallet_for_work = add_wallet;
    
    }

    function _burn_payment(uint256 index) public  {
        if (index < pre_pool_len){
            address user_address = payment_application[pre_pool[index]].user_wallet;
            if (payment_application[pre_pool[index]].fallacy == true){
                _transfer(multiplicator, user_address, payment_application[pre_pool[index]].amount);  
            }
            else{ 
                change_wallet_level(user_address);
                if (!_transfer(multiplicator, payment_application[pre_pool[index]].wallet_for_withdraw, payment_application[pre_pool[index]].amount_for_withdraw))
                    return;
            }
            payment_application[pre_pool[index]].isRepaid = true;
            user[user_address].all_withdraw_payments[user[user_address].all_withdraw_payments_len] = pre_pool[index];
            user[user_address].all_withdraw_payments_len += 1;
            pre_pool[index] = pre_pool[pre_pool_len-1];
            pre_pool[pre_pool_len-1] = 0;
            if (pre_pool_len > 0) pre_pool_len -= 1; 
            user[user_address].last_update_timestamp = block.timestamp;
         } 
    }

    function admin_change_velocity(uint256 _a, uint256 _b ) onlyAdmin(msg.sender) public{
        lower_bound_random_day = _a;
        upper_bound_random_day = _b;
    }

    function check_and_pay() public {
        if (pre_pool_len == 0) return;
        uint256 i = 0;
        uint256 count_burned_payments =  0;
        
            for (i = last_pool_i; i < last_pool_i + section_payment_len; i++){

                if (i > pre_pool_len) break;

                if (payment_application[pre_pool[i]].reward_time <= current_day) { 
                    _burn_payment(i);
                    count_burned_payments += 1;
                }

                if (count_burned_payments >= 2) break;

            }
            last_pool_i = i;
            
    }


    function fallacy_add_to_pool_for_day(address user_address, uint256 _value) internal  {
        pre_pool[pre_pool_len] = application_number;
        pre_pool_len += 1;
        payment_application[application_number].fallacy = true;
        payment_application[application_number].user_wallet = user_address;
        payment_application[application_number].amount = _value;
        payment_application[application_number].amount_for_withdraw = _value;
        payment_application[application_number].wallet_for_withdraw = user[user_address].wallet_for_work;
        payment_application[application_number].payment_time = current_day; 
        payment_application[application_number].reward_time = payment_application[application_number].payment_time + 1; 
        application_number += 1;
    }
        
    function user_withdraw_today_summ(address user_address) internal view returns (uint256) {
        uint256 summ = 0;
        for (uint256 i=0; i < user[user_address].tranz_withdraw_in_day[current_day].length;i++){
            summ += user[user_address].tranz_withdraw_in_day[current_day][i];
        }
        return summ;
    }
     function user_permission_for_withdraw(address user_address, uint256 value) public view returns (bool)  {
        if (user[user_address].isWithdraw == false){
            return true;
        }
        else {
            if (user_withdraw_today_summ(user_address) + value <= withdraw_limits[user[user_address].level]){
                return true;
            } 
            else{
                return false;
            }
        }
     }

    function add_to_pool(address user_address, uint256 value, uint256 number_of_DAYs) internal {
        
        
        
        
        address wallet_for_work = user[user_address].wallet_for_work;
        uint256 add_coef_forging_reward = 0;
        if (user[user_address].is_forging){
            add_coef_forging_reward = 2;
        }
        payment_application[application_number].amount_for_withdraw =  ((coefs[user[user_address].add_wallet_level[wallet_for_work]] + min(user[user_address].active, 5) )* (10 + add_coef_forging_reward) + 1000 ) * value / 1000; 
        payment_application[application_number].balance = balanceOf[user_address];
        payment_application[application_number].amount = value;
        
        pre_pool[pre_pool_len] = application_number;
        pre_pool_len += 1;
        user[user_address].all_payments[user[user_address].all_payments_len]  = application_number;
        user[user_address].all_payments_len += 1;
        
        
        if (user[user_address].tranz_in_day[wallet_for_work][current_day].length < max_array_len) {
            user[user_address].tranz_in_day[wallet_for_work][current_day].push(application_number) ;
        } 

        if (user[user_address].isWithdraw == false){    
            payment_application[application_number].wallet_for_withdraw = user_address;
        }
        else{
            payment_application[application_number].wallet_for_withdraw = user[user_address].wallet_for_work;
            if (user[user_address].tranz_withdraw_in_day[current_day].length < max_array_len){
                user[user_address].tranz_withdraw_in_day[current_day].push(application_number);
            }
        }
        payment_application[application_number].user_wallet= user_address;
        
        payment_application[application_number].payment_time= current_day;
        payment_application[application_number].reward_time= payment_application[application_number].payment_time + number_of_DAYs;
        application_number += 1;
        
    }

    function reward_for_referers(address user_address, uint256 value) internal {
        address referer = user[user_address].referer;
        uint256 bonus1 = value / 200;
        uint256 bonus2 = value / 200;
        for (uint256 i = 0; i < 10; i++){ 
            if (bonus1 > 0){
                
                if (user[referer].level >= user[user_address].level){
                _transfer(multiplicator, referer, bonus1);
                bonus1 = 0;
                }
                else {
                    user[referer].lost_referal_funds += bonus1;
                }
            }
            if (bonus2 > 0 ){
                
               if (user[referer].level >= 4){
                _transfer(multiplicator, referer, bonus2);
                bonus2 = 0;
                }
                else {
                    user[referer].lost_referal_funds += bonus2;
                }
            }
            
            if (bonus1 == 0 && bonus2 == 0){
                break;
            }
            referer = user[referer].referer;
        }
        
    }

    function _transfer(address _from, address _to, uint256 _value) internal returns (bool){
        if (balanceOf[_from] >= _value) {
            balanceOf[_from] = balanceOf[_from] - _value;
            balanceOf[_to] = balanceOf[_to] + _value;
            emit Transfer(_from, _to, _value);
            return true;
        }
        else {
            return false;
        }
    }

    function gift_transfer(address _from, address _to, uint256 _value) public onlyAdmin(msg.sender) returns (bool){
        require(user[_from].is_registered,"User is not registered");
        require(_value <= 10 * ZHC,"Gift amount <= 10");
        require(the_amount_of_accepted_gifts[_to] < 25 * ZHC);
        if (_transfer(_from, _to, _value)){
            the_amount_of_accepted_gifts[_to] += _value;
            return true;
        }
        else {
            return false;
        }
        
    }

  function random(uint256 start, uint256 finish) public returns (uint256) {
        random_counter++;
        uint256 r =  start + uint256(keccak256(abi.encodePacked(block.number, blockhash(block.timestamp), block.timestamp,random_counter))) % (finish - start); 
        return r;
    }

   
    function transfer(address _to, uint256 _value)
    public
    validAddress(_to)
    returns (bool success)
    {   
        require(msg.sender != owner,"Owner can't transfer");
        require(msg.sender != multiplicator,"Multiplicator can't transfer");
        address _from = msg.sender;
        return admin_transfer_internal( _from, _to, _value);   
    }


    function admin_transfer_internal(address _from, address _to,  uint256 _value)
    internal
    validAddress(_to) 
    returns (bool success)
    {   //10000 
        
        if (_to == address(this)){
            (success, ) = usdt_contract.call(abi.encodeWithSignature("transfer(address,uint256)",  msg.sender, _value));
            if (success) {
                _transfer(_from, _to, _value);
            }
            return success;
        }

        if (_from == first_user){
            return _transfer(_from, _to, _value);     
        }
        
        if (_to == multiplicator ){ 
            
            
            if (user[_from].is_registered == false){
                    return false;
            }
            check_new_day();
            change_wallet_level(_from);
            uint256 number_of_payments = _value / one_payment;
            if (user_permission_for_withdraw(_from, _value) && _value >= one_payment && _value % one_payment == 0 ){

                reward_for_referers(_from, _value); 
                if ( _value <= 5 * one_payment ){ 
                    
                    for (uint256 i = 0; i < number_of_payments; i++){
                        check_and_pay();
                        add_to_pool(_from, one_payment, i == 0 ? 5 : random(lower_bound_random_day, upper_bound_random_day)); 
                        
                    } 
                    
                }  
                else {
                    for (uint256 i=0; i < 5; i++){
                        check_and_pay();
                        add_to_pool(_from, _value / 5 , i == 0 ? 5 : random(lower_bound_random_day, upper_bound_random_day)); 
                    } 
                      
                }   
            }
            else {
                fallacy_add_to_pool_for_day(_from, _value);   
                check_and_pay();
                user[_from].wallet_for_work = _from;   
            }
             
            user[_from].last_update_timestamp = block.timestamp;  
            full_amount += _value;  
        }
        else {
            if (user[_from].is_registered == true && user[_to].is_registered == false ){
                    return false;
            }
        }
        
        return _transfer(_from, _to, _value);
    }

    function admin_transfer(address _from,  uint256 _value)
    public 
    onlyAdmin(msg.sender)
    returns (bool success)
    {   
        require(user[_from].is_registered,"User _from not registered");
        return admin_transfer_internal(_from, multiplicator, _value * 10 ** decimals); 
    } 

    function admin_transfer_add_wallet(address _from,address _add_wallet,  uint256 _value )
    public
    onlyAdmin(msg.sender)
    returns (bool success)
    {   
        require(user[_from].is_registered,"User not registered");  
        require(is_address_in_add_wallets(_from, _add_wallet));
        user[_from].wallet_for_work = _add_wallet;   
        return admin_transfer_internal(_from, multiplicator, _value * 10 ** decimals);  
    } 

    function transferFrom(address _from, address _to, uint256 _value)
    public
    validAddress(_from)
    validAddress(_to) 
    returns (bool success)
    {
        require(_from != owner,"Owner can't transfer");
        require(_from != multiplicator,"Multiplicator can't transfer");
        allowance[_from][msg.sender] = allowance[_from][msg.sender] - _value;
        balanceOf[_from] = balanceOf[_from] - _value;
        balanceOf[_to] = balanceOf[_to] + _value;
        emit Transfer(_from, _to, _value);
        return true;
    }

    function transferForUSDZ(address _to, uint256 _value)
    public
    returns (bool)
    {   
        require(msg.sender == usdt_contract, "You are not USDZ contract");
        address _from = address(this);
        balanceOf[_from] -= _value;
        balanceOf[_to] += _value;
        emit Transfer(_from, _to, _value);
        return true;
    }

    function approve(address _spender, uint256 _value)
    public
    validAddress(_spender)
    returns (bool success)
    {
        require(msg.sender != owner,"Owner can't approve");
        require(msg.sender != multiplicator,"Multiplicator can't approve");
        require(_value == 0 || allowance[msg.sender][_spender] == 0);
        allowance[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    receive () payable external  { 
        require(msg.value >= ZHC);
        forging_node[msg.sender][0] = true;
        payable(msg.sender).transfer(msg.value);
    }

    fallback() payable external {
        require(msg.value >= ZHC);
        forging_node[msg.sender][0] = true;
        payable(msg.sender).transfer(msg.value);
    }

    function registrate_node_in_smartcontract() public {
        forging_node[msg.sender][0] = true;
    }

    function top_up_multiplicator_balance() public {
        if (balanceOf[multiplicator] < 10 * 10 ** 6 * ZHC ){
            _transfer(owner, multiplicator, 10 * 10 ** 6 * ZHC );
        }
    }

    function add_admin(address wallet) onlyAdmin(msg.sender) public {
        require(prestart);
        all_admins.push(wallet);
        is_admin[wallet] = true;
    }

    function clear_admins() onlyAdmin(msg.sender) public {
         for (uint256 i = 3; i < all_admins.length; i++){
            is_admin[all_admins[i]] = false;
        }
    }

    function change_prestart() onlyAdmin(msg.sender) public {
        prestart = !prestart;
    }

    function admin_pereregistrate(address referer_address, address user_address) onlyAdmin(msg.sender) public {
        require(prestart);
        user[user_address].is_registered = true;
        user[user_address].wallet_for_work = user_address;
        user[user_address].referer = referer_address;
        user[user_address].add_wallets = [user_address];
        user[user_address].isWithdraw = false; 
        user[user_address].level = 0;
        user[user_address].is_forging = false;
    }


}