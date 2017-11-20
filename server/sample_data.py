from models import *

def initial_data():
    # let's create static data according with GET_OR_CREATE technique as in https://stackoverflow.com/questions/8447502/how-to-do-insert-if-not-exist-else-update-with-mongoengine
    Currency.objects(code="ZEC").update_one(algo='Equihash', upsert=True)
    Currency.objects(code="DCR").update_one(algo='Blake', upsert=True)
    Currency.objects(code="SIA").update_one(algo='Blake', upsert=True)
    Currency.objects(code="ETH").update_one(algo='Ethash', upsert=True)
    Currency.objects(code="ETC").update_one(algo='Ethash', upsert=True)
    Currency.objects(code="BTC").update_one(algo='SHA256', upsert=True)
    Currency.objects(code="BCC").update_one(algo='SHA256', upsert=True)
    Exchange.objects(name="Poloniex").update_one(website="https://poloniex.com", upsert=True)

    miner_program = MinerProgram.objects(name='Claymore Dual').modify(
        upsert=True,
        set__family = 'claymore',
        set__code = 'claymore_dual',
        set__dir = 'claymore10',
        set__win_exe = 'EthDcrMiner64.exe',
        set__command_line = '-epool %POOL_SERVER%:%POOL_PORT% -ewal %POOL_ACCOUNT%.%WORKER% -r 1 -mport 3333 -retrydelay 3 -mode 0 -erate 1 -estale 0 -dpool %DUAL_POOL_SERVER%:%DUAL_POOL_PORT% -dwal %DUAL_POOL_ACCOUNT%.%DUAL_WORKER% -ftime 10 -dcri 26 -asm 1',
        set__env = {
            'GPU_MAX_HEAP_SIZE': '100',
            'GPU_USE_SYNC_OBJECTS': '1',
            'GPU_MAX_ALLOC_PERCENT': '100',
            'GPU_SINGLE_ALLOC_PERCENT': '100',
            'GPU_FORCE_64BIT_PTR': '0',
        },
    )

    miner_program = MinerProgram.objects(name='Claymore').modify(
        upsert=True,
        set__family = 'claymore',
        set__code = 'claymore',
        set__dir = 'claymore10',
        set__win_exe = 'EthDcrMiner64.exe',
        set__command_line = '-epool %POOL_SERVER%:%POOL_PORT% -ewal %POOL_ACCOUNT%.%WORKER% -r 1 -mport 3333 -retrydelay 3 -mode 1 -erate 1 -estale 0 -ftime 10 -asm 1',
        set__env={
            'GPU_MAX_HEAP_SIZE': '100',
            'GPU_USE_SYNC_OBJECTS': '1',
            'GPU_MAX_ALLOC_PERCENT': '100',
            'GPU_SINGLE_ALLOC_PERCENT': '100',
            'GPU_FORCE_64BIT_PTR': '0',
        },
    )

    miner_program = MinerProgram.objects(name='EWBF').modify(
        upsert=True,
        set__family = 'ewbf',
        set__code = 'ewbf',
        set__dir = 'ewbf_0.3.4b',
        set__win_exe = 'miner.exe',
        set__command_line = '--server %POOL_SERVER% --port %POOL_PORT% --user %POOL_ACCOUNT%.%WORKER% --pass %POOL_PASSWORD% --eexit 3 --fee 0.5',
        set__env={
            'GPU_MAX_HEAP_SIZE': '100',
            'GPU_USE_SYNC_OBJECTS': '1',
            'GPU_MAX_ALLOC_PERCENT': '100',
            'GPU_SINGLE_ALLOC_PERCENT': '100',
            'GPU_FORCE_64BIT_PTR': '0',
        },
    )


def test_data():
    miner_program = MinerProgram.objects(name='Pseudo Claymore Miner').modify(
        upsert=True,
        set__family = 'claymore',
        set__code = 'pseudo_claymore_miner',
        set__dir = 'miner_emu',
        set__win_exe = 'python.exe',
        set__command_line = '-u miner_emu.py --file %CURRENCY%%DUAL_CURRENCY%.txt --delay 0.3 ',
        set__env={
            'GPU_MAX_HEAP_SIZE': '100',
            'GPU_USE_SYNC_OBJECTS': '1',
            'GPU_MAX_ALLOC_PERCENT': '100',
            'GPU_SINGLE_ALLOC_PERCENT': '100',
            'GPU_FORCE_64BIT_PTR': '0',
        },
    )

    miner_program = MinerProgram.objects(name='Pseudo EWBF Miner').modify(
        upsert=True,
        set__family = 'ewbf',
        set__code = 'pseudo_ewbf_miner',
        set__dir = 'miner_emu',
        set__win_exe = 'python.exe',
        set__command_line = '-u miner_emu.py --file %CURRENCY%%DUAL_CURRENCY%.txt --delay 1 ',
        set__env={
            'GPU_MAX_HEAP_SIZE': '100',
            'GPU_USE_SYNC_OBJECTS': '1',
            'GPU_MAX_ALLOC_PERCENT': '100',
            'GPU_SINGLE_ALLOC_PERCENT': '100',
            'GPU_FORCE_64BIT_PTR': '0',
        },
    )

    poloniex = Exchange.objects(name="Poloniex").modify(
        upsert=True,
        set__name="Poloniex"
    )

    user = User.objects.get(email='egor.fedorov@gmail.com')
    mp_pc = MinerProgram.objects.get(code="pseudo_claymore_miner")
    cg = ConfigurationGroup.objects(name="Test ETH+DCR").modify(
        upsert=True,
        set__user = user,
    	set__currency = Currency.objects.get(code="ETH"),
    	set__miner_program = mp_pc,
        set__command_line=mp_pc.command_line,
        set__env=mp_pc.env,
        set__pool = Pool.objects.get(name="Ethermine"),
    	set__pool_login = "0x397b4b2fa22b8154ad6a92a53913d10186170974",
    	set__pool_password = "x",
    	set__exchange = poloniex.id,
    	set__wallet = "0x397b4b2fa22b8154ad6a92a53913d10186170974",
    	set__is_dual = True,
    	set__dual_currency = Currency.objects.get(code="DCR"),
    	set__dual_pool = Pool.objects.get(name="Decred Coinmine"),
    	set__dual_pool_login = "egoaga19",
    	set__dual_pool_password = "x",
    	set__dual_exchange = poloniex.id,
    	set__dual_wallet = "DsZAfQcte7c6xKoaVyva2YpNycLh2Kzc8Hq",
    )

    cg = ConfigurationGroup.objects(name="Test ETH").modify(
        upsert=True,
        set__user=user,
        set__currency = Currency.objects.get(code="ETH"),
        set__miner_program=mp_pc,
        set__command_line=mp_pc.command_line,
        set__env=mp_pc.env,
        set__pool = Pool.objects.get(name="Ethermine"),
    	set__pool_login = "0x397b4b2fa22b8154ad6a92a53913d10186170974",
    	set__pool_password = "x",
    	set__exchange = poloniex.id,
    	set__wallet = "0x397b4b2fa22b8154ad6a92a53913d10186170974",
    	set__is_dual = False,
    )

    mp_pe = MinerProgram.objects.get(code="pseudo_ewbf_miner")

    cg = ConfigurationGroup.objects(name="Test ZEC").modify(
        upsert=True,
        set__user = user,
        set__miner_program=mp_pe,
        set__command_line=mp_pe.command_line,
        set__env=mp_pe.env,
        set__currency = Currency.objects.get(code="ZEC"),
    	set__pool = Pool.objects.get(name="FlyPool"),
    	set__pool_login = "t1Q99nQXpQqBbutcaFhZSe3r93R9w4HzV2Q",
    	set__pool_password = "x",
    	set__exchange = poloniex.id,
    	set__wallet = "t1Q99nQXpQqBbutcaFhZSe3r93R9w4HzV2Q",
    	set__is_dual = False,
    )





def sample_data():

    user = User.objects(email='egor.fedorov@gmail.com').modify(
        upsert=True,
        name="Egor Fedorov",
        target_currency="RUR",
    )


    pool = Pool.objects(name="Ethermine").modify(
        upsert=True,
    	set__pool_family = "ethermine",
    	set__info = "",
    	set__website = "https://ethermine.org",
    	set__currency = Currency.objects.get(code="ETH"),
    	set__fee = 0.01,
    	set__servers = ['us1.ethermine.org:4444', 'us1.ethermine.org:14444', 'eu1.ethermine.org:4444',
                    'eu1.ethermine.org:14444'],
    	set__server = 'eu1.ethermine.org:4444',
    )

    pool = Pool.objects(name= "FlyPool").modify(
        upsert=True,
        set__pool_family = "ethermine",
    	set__info = "Zcash 	pool",
    	set__website = "http://zcash.flypool.org",
    	set__currency = Currency.objects.get(code="ZEC"),
    	set__fee = 0.01,
    	set__servers = ['asia1-zcash.flypool.org:3333', 'eu1-zcash.flypool.org:3333', 'eu1-zcash.flypool.org:13333'],
    	set__server = 'eu1-zcash.flypool.org:3333',
    )

    pool = Pool.objects(name="Decred Coinmine").modify(
        upsert = True,
        set__pool_family = "coinmine",
        set__info = "",
        set__website = "https://www2.coinmine.pl/dcr/index.php?page=statistics&action=pool",
        set__currency = Currency.objects.get(code="DCR"),
        set__fee = 0.01,
        set__servers = ['dcr.coinmine.pl:2222', 'dcr-eu.coinmine.pl:2222', 'dcr-us.coinmine.pl:2222',
                'dcr-as.coinmine.pl:2222'],
        set__server = 'dcr.coinmine.pl:2222',
    )
    
    poloniex = Exchange.objects.get(name="Poloniex")

    mp_cd = MinerProgram.objects.get(code="claymore_dual")
    cg = ConfigurationGroup.objects(name="ETH+DCR(poloniex)").modify(
        upsert=True,
        set__user = user,
        set__command_line = mp_cd.command_line,
        set__currency = Currency.objects.get(code="ETH"),
    	set__miner_program = mp_cd,
    	set__pool = Pool.objects.get(name="Ethermine"),
    	set__pool_login = "0x397b4b2fa22b8154ad6a92a53913d10186170974",
    	set__pool_password = "x",
    	set__exchange = poloniex,
    	set__wallet = "0x397b4b2fa22b8154ad6a92a53913d10186170974",
    	set__is_dual = True,
    	set__dual_currency = Currency.objects.get(code="DCR"),
    	set__dual_pool = Pool.objects.get(name="Decred Coinmine"),
    	set__dual_pool_login = "egoaga19",
    	set__dual_pool_password = "x",
    	set__dual_exchange = poloniex,
    	set__dual_wallet = "DsZAfQcte7c6xKoaVyva2YpNycLh2Kzc8Hq",
    )

    mp_c = MinerProgram.objects.get(code="claymore")
    cg = ConfigurationGroup.objects(name="ETH(poloniex)").modify(
        upsert=True,
        set__user=user,
        set__miner_program=mp_c,
        set__command_line = mp_c.command_line,
        set__env = mp_c.env,
        set__currency = Currency.objects.get(code="ETH"),
    	set__pool = Pool.objects.get(name="Ethermine"),
    	set__pool_login = "0x397b4b2fa22b8154ad6a92a53913d10186170974",
    	set__pool_password = "x",
    	set__exchange = Exchange.objects.get(name="Poloniex"),
    	set__wallet = "0x397b4b2fa22b8154ad6a92a53913d10186170974",
    	set__is_dual = False,
    )

    mp_e = MinerProgram.objects.get(code="ewbf")
    cg = ConfigurationGroup.objects(name="ZEC(poloniex)").modify(
        upsert=True,
        set__user=user,
        set__miner_program=mp_e,
        set__command_line = mp_e.command_line,
        set__env = mp_e.env,
        set__currency = Currency.objects.get(code="ZEC"),
    	set__pool = Pool.objects.get(name="FlyPool"),
    	set__pool_login = "t1Q99nQXpQqBbutcaFhZSe3r93R9w4HzV2Q",
    	set__pool_password = "x",
    	set__exchange = Exchange.objects.get(name="Poloniex"),
    	set__wallet = "t1Q99nQXpQqBbutcaFhZSe3r93R9w4HzV2Q",
    	set__is_dual = False,
    )
