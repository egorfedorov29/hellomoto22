import json


class CryptoDataProvider:
    '''
    Usage:

    crypto_data = CryptoDataProvider("coins1.json")

    mh = 141
    units = "Mh/s"
    hashrate = crypto_data.hashrate_from_units(mh, units)
    print(hashrate)
    currency = 'ETH'
    data = crypto_data.for_currency(currency)
    profit = crypto_data.calc_profit(data, hashrate)
    print("Daily profit for %d %s = %.5f %s" % (mh, units, profit, currency))
    '''

    def __init__(self, filename) -> None:
        self.filename = filename
        self.currencies_info = []
        self.update()

    def update(self):
        self.currencies_info = json.load(open(self.filename))['coins']

    def for_currency(self, currency):
        for name, currency_info in self.currencies_info.items():
            if currency_info['tag'] == currency:
                return currency_info
        raise Exception("No data for currency %s" % currency)

    def hashrate_from_units(self, value, units):
        unit_measures = {
            "h/s": 1,
            "Kh/s": 1e3,
            "Mh/s": 1e6,
            "Gh/s": 1e9,
            "Th/s": 1e12,
            "Ph/s": 1e15,
            "Sol/s": 1,
            "KSol/s": 1e3,
            "MSol/s": 1e6,
            "GSol/s": 1e9,
        }
        if units in unit_measures.keys():
            return value * unit_measures[units]
        raise Exception("Unknown measurement unit %s. Known units %s" % (units, unit_measures.keys()))

    def calc_profit(self, coin_data, hashrate, period=86400):
        '''
        * считаем сколько монет за определенное время можем получить на данном оборудовании
        N = (t*R*H)/(D*2^32)
        где:
        N - доход в монетах
        t - период майнинга в секундах (например, сутки = 86400)
        R - награда за блок в монетах
        H - хэшрейт в секунду (например, 1ГХш = 1000000000)
        D - сложность

        доход в сутки = ( мощность фермы / мощность сети ) Х кол-во монет в сутки
        кол-во монет в сутки  = ( 86400 Х монет за блок ) / время нахождения блока

        :param coin_data: the data generated by for_currency("ETH")
        :param hashrate:
        :param period:
        :return: amount of currency earned during period
        '''
        net_hash = coin_data["nethash"]
        block_time = float(coin_data["block_time"])
        # некорректно считает например для FTC difficulty == 56. Example:
        # block_time = coin_data["difficulty"] / net_hash
        block_reward = float(coin_data["block_reward"])
        user_ratio = hashrate / net_hash
        net_reward = period / block_time * block_reward
        user_reward = net_reward * user_ratio
        return user_reward