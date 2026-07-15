"""النسخة النهائية: USDA SR Legacy -> أصول قاعدة الأكل بتاعة التطبيق.

قاعدة صارمة: **كل رقم غذائى بيتنقل حرفياً من USDA**. اللى بنكتبه بالعربى هو
الأسماء بس (ترجمة اسم = آمن؛ اختراع رقم = ممنوع).
"""
import zipfile, csv, io, json, re, collections, os

Z = zipfile.ZipFile('usda.zip')
B = 'FoodData_Central_sr_legacy_food_csv_2018-04/'


def rows(name):
    with Z.open(B + name) as f:
        yield from csv.DictReader(io.TextIOWrapper(f, 'utf-8-sig'))


WANT = {
    1008: 'kcal', 1003: 'protein', 1004: 'fat', 1005: 'carbs',
    1079: 'fiber', 2000: 'sugar', 1093: 'sodium', 1253: 'chol',
    1258: 'sat', 1087: 'calcium', 1089: 'iron', 1092: 'potassium',
}

PREP = [
    (r'pan-fried|deep fried|\bfried\b', 'fried'),
    (r'oven-roasted|\broasted\b', 'roasted'),
    (r'\bgrilled\b|\bbroiled\b', 'grilled'),
    (r'\bboiled\b', 'boiled'),
    (r'\bsteamed\b', 'steamed'),
    (r'\bbaked\b', 'baked'),
    (r'\bstewed\b|\bbraised\b|\bsimmered\b', 'stewed'),
    (r'\bmicrowave\w*', 'microwaved'),
    (r'\bcooked\b', 'cooked'),
    (r'\bcanned\b', 'canned'),
    (r'\bdried\b|\bdehydrated\b', 'dried'),
    (r'\bfrozen\b', 'frozen'),
    (r'\braw\b', 'raw'),
]

STRIP = re.compile(
    r',?\s*\b(cooked|raw|boiled|fried|pan-fried|roasted|oven-roasted|grilled|broiled|'
    r'steamed|baked|stewed|braised|simmered|microwaved?|drained|with salt|without salt|'
    r'salt added|salt not added|unprepared|prepared|as purchased|heated|oven-heated|'
    r'reheated|dry heat|moist heat)\b', re.I)

# ————— فلترة: مش مناسب للمستخدم (مسلم مصرى) أو ضوضاء —————
DROP_CATS = {'Pork Products', 'American Indian/Alaska Native Foods'}
DROP_RE = re.compile(
    r'\b(pork|bacon|ham,|ham |prosciutto|lard|bratwurst|kielbasa|beerwurst|'
    r'alcoholic|beer\b|wine\b|liqueur|whiskey|vodka|rum\b|gin,|tequila|'
    r'whale|seal,|sea lion|walrus|bear,|beluga|caribou|moose|muskrat|'
    r'\bswine\b)', re.I)

# جولة ٢ (باختيار المستخدم): بنود تانية ما تصلحش.
# ⚠️ اتكتبت بدقة عشان الإيجابيات الكاذبة:
#   - «Beans, black turtle» = فاصوليا سودا مش سلاحف -> بنطلب «Turtle, green» بس
#   - «KLONDIKE SLIM-A-BEAR» = أيس كريم مش لحم دب -> مفيش قاعدة لـbear هنا
#   - «Turkey Pepperoni» = ديك رومى حلال -> بنستثنيه من قاعدة البيبرونى
#   - «Vanilla extract, imitation, no alcohol» = من غير كحول -> بيفضل
DROP2 = [
    # بيبرونى/سلامى الخنزير — إلا لو ديك رومى
    (re.compile(r'\b(pepperoni|salami)\b', re.I), re.compile(r'\bturkey\b', re.I)),
    # دم
    (re.compile(r'\bblood sausage\b|\bblood pudding\b|black pudding', re.I), None),
    # جيلاتين ومنفحة (مصدر حيوانى مجهول) — لاحظ الجمع «Gelatins»
    (re.compile(r'\bgelatins?\b|\brennin\b|\brennet\b', re.I), None),
    # خلاصة فانيليا بكحول (مش «no alcohol»)
    (re.compile(r'\bvanilla extract\b', re.I), re.compile(r'no alcohol', re.I)),
    # خيل / ضفادع / سلاحف
    (re.compile(r'\bhorse\b|\bdonkey\b|\bmule\b|\bfrog legs\b', re.I), None),
    (re.compile(r'^turtle,\s*green', re.I), None),
    # شحم بقرى
    (re.compile(r'\bbeef tallow\b', re.I), None),
]

# اللحوم/الدواجن/الأسماك النيّئة — ما بتتاكلش نيّئة (الخضار والفاكهة النيّئة بتفضل)
RAW_MEAT_CATS = {
    'Beef Products', 'Poultry Products', 'Lamb, Veal, and Game Products',
    'Finfish and Shellfish Products', 'Sausages and Luncheon Meats',
}


def drop2_hit(desc):
    """هل الصنف بيقع تحت جولة الفلترة التانية؟ (مع مراعاة الاستثناءات)"""
    for pat, keep_if in DROP2:
        if pat.search(desc) and not (keep_if and keep_if.search(desc)):
            return True
    return False

# ————— قاموس الأسماء (عربى) — أسماء بس، مفيش أرقام —————
HEAD = {
    'beef': 'لحمة بقرى', 'lamb': 'ضانى', 'veal': 'بتلو', 'chicken': 'فراخ',
    'turkey': 'ديك رومى', 'duck': 'بط', 'goose': 'وز', 'quail': 'سمان',
    'pheasant': 'دراج', 'ostrich': 'نعام', 'emu': 'إيمو', 'game meat': 'لحم صيد',
    'fish': 'سمك', 'mollusks': 'رخويات', 'crustaceans': 'قشريات',
    'egg': 'بيض', 'cheese': 'جبنة', 'milk': 'لبن', 'yogurt': 'زبادى',
    'cream': 'كريمة', 'sour cream': 'كريمة حامضة', 'butter': 'زبدة',
    'whey': 'شرش اللبن', 'soymilk': 'لبن صويا', 'soymilk (all flavors)': 'لبن صويا',
    'tofu': 'توفو', 'soybeans': 'فول صويا', 'soy flour': 'دقيق صويا',
    'rice': 'رز', 'pasta': 'مكرونة', 'spaghetti': 'اسباجيتى', 'noodles': 'نودلز',
    'macaroni and cheese': 'مكرونة بالجبنة', 'lasagna': 'لازانيا',
    'bread': 'عيش', 'rolls': 'أصابع عيش', 'bagels': 'بيجل', 'tortillas': 'تورتيلا',
    'english muffins': 'مافن إنجليزى', 'croissants': 'كرواسون', 'biscuits': 'بسكويت',
    'crackers': 'كراكرز', 'cookies': 'كوكيز', 'cookie': 'كوكيز', 'cake': 'كيكة',
    'pie': 'فطيرة', 'pie crust': 'عجينة فطيرة', 'pie fillings': 'حشو فطيرة',
    'muffins': 'مافن', 'pancakes': 'بان كيك', 'waffles': 'وافل',
    'doughnuts': 'دوناتس', 'danish pastry': 'دانش', 'sweet rolls': 'لفائف حلوة',
    'toaster pastries': 'فطائر توستر', 'turnover': 'فطيرة محشية',
    'wheat flour': 'دقيق قمح', 'wheat': 'قمح', 'corn flour': 'دقيق ذرة',
    'cornmeal': 'دقيق ذرة خشن', 'corn': 'ذرة', 'barley': 'شعير', 'millet': 'دخن',
    'cereals': 'حبوب إفطار', 'cereals ready-to-eat': 'حبوب إفطار جاهزة',
    'potatoes': 'بطاطس', 'sweet potato': 'بطاطا', 'taro': 'قلقاس',
    'tomatoes': 'طماطم', 'tomato products': 'منتجات طماطم', 'onions': 'بصل',
    'garlic': 'توم', 'carrots': 'جزر', 'peppers': 'فلفل', 'eggplant': 'باذنجان',
    'cucumber': 'خيار', 'zucchini': 'كوسة', 'squash': 'قرع', 'pumpkin': 'قرع عسلى',
    'okra': 'بامية', 'jute': 'ملوخية', 'spinach': 'سبانخ', 'lettuce': 'خس',
    'cabbage': 'كرنب', 'cauliflower': 'قرنبيط', 'broccoli': 'بروكلى',
    'peas': 'بسلة', 'beans': 'فاصوليا', 'lima beans': 'فاصوليا ليما',
    'mung beans': 'فول مونج', 'lentils': 'عدس', 'chickpeas (garbanzo beans': 'حمص',
    'cowpeas': 'لوبيا', 'cowpeas (blackeyes)': 'لوبيا', 'broadbeans': 'فول',
    'broadbeans (fava beans)': 'فول', 'refried beans': 'فاصوليا مهروسة',
    'beets': 'بنجر', 'beet greens': 'ورق بنجر', 'radishes': 'فجل',
    'turnips': 'لفت', 'turnip greens': 'ورق لفت', 'kale': 'كيل',
    'collards': 'كرنب أخضر', 'mustard greens': 'ورق خردل', 'chard': 'سلق',
    'celery': 'كرفس', 'leeks': 'كرات', 'asparagus': 'أسبراجس',
    'artichokes': 'خرشوف', 'mushrooms': 'مشروم', 'brussels sprouts': 'كرنب بروكسل',
    'kohlrabi': 'كرنب لفتى', 'seaweed': 'أعشاب بحرية', 'bamboo shoots': 'براعم بامبو',
    'plantains': 'موز مطبوخ', 'vegetables': 'خضار', 'succotash': 'ذرة وفاصوليا',
    'peas and carrots': 'بسلة وجزر', 'peas and onions': 'بسلة وبصل',
    'apples': 'تفاح', 'applesauce': 'صوص تفاح', 'apricots': 'مشمش',
    'pears': 'كمثرى', 'peaches': 'خوخ', 'plums': 'برقوق', 'cherries': 'كريز',
    'grapes': 'عنب', 'oranges': 'برتقال', 'tangerines': 'يوسفى',
    'grapefruit': 'جريب فروت', 'lemon': 'لمون', 'melons': 'شمام',
    'pineapple': 'أناناس', 'strawberries': 'فراولة', 'blueberries': 'توت أزرق',
    'blackberries': 'توت أسود', 'raspberries': 'توت العليق', 'cranberries': 'توت برى',
    'currants': 'كشمش', 'figs': 'تين', 'dates': 'بلح', 'avocados': 'أفوكادو',
    'bananas': 'موز', 'mangos': 'مانجا', 'guavas': 'جوافة', 'pomegranates': 'رمان',
    'watermelon': 'بطيخ', 'fruit salad': 'سلطة فواكه', 'fruit cocktail': 'كوكتيل فواكه',
    'rhubarb': 'راوند',
    'orange juice': 'عصير برتقال', 'apple juice': 'عصير تفاح',
    'grapefruit juice': 'عصير جريب فروت', 'pineapple juice': 'عصير أناناس',
    'grape juice': 'عصير عنب', 'lemonade': 'ليموناضة',
    'cranberry juice cocktail': 'عصير توت برى', 'fruit juice smoothie': 'سموذى',
    'lemon juice from concentrate': 'عصير لمون مركّز',
    'beverages': 'مشروبات', 'water': 'مياه', 'carbonated beverage': 'مشروب غازى',
    'cocoa': 'كاكاو', 'chocolate': 'شوكولاتة', 'baking chocolate': 'شوكولاتة خام',
    'nuts': 'مكسرات', 'peanuts': 'فول سودانى', 'peanut butter': 'زبدة فول سودانى',
    'seeds': 'بذور', 'oil': 'زيت', 'fish oil': 'زيت سمك', 'olive': 'زيتون',
    'margarine': 'مارجرين', 'margarine-like': 'شبه مارجرين',
    'margarine-like spread': 'دهن نباتى', 'shortening': 'دهن نباتى صلب',
    'fat': 'دهن', 'mayonnaise': 'مايونيز', 'salad dressing': 'صوص سلطة',
    'creamy dressing': 'صوص كريمى', 'vinegar': 'خل', 'sauce': 'صوص',
    'gravy': 'مرقة', 'dip': 'ديب', 'soup': 'شوربة', 'stew': 'يخنة',
    'spices': 'بهارات', 'pickles': 'مخلل', 'sweeteners': 'محليات',
    'sugars': 'سكر', 'syrups': 'شراب سكرى', 'syrup': 'شراب سكرى',
    'honey': 'عسل نحل', 'jams and preserves': 'مربى', 'jellies': 'جيلى',
    'candies': 'حلويات', 'sweets': 'حلويات', 'desserts': 'حلو',
    'puddings': 'مهلبية/بودنج', 'gelatin desserts': 'جيلى', 'flan': 'كريم كراميل',
    'egg custards': 'كسترد', 'ice cream': 'أيس كريم', 'ice creams': 'أيس كريم',
    'light ice cream': 'أيس كريم لايت', 'frozen yogurts': 'زبادى مجمّد',
    'frozen novelties': 'حلويات مجمدة', 'ice cream sandwich': 'ساندوتش أيس كريم',
    'frostings': 'تزيين كيك', 'toppings': 'صوص تزيين',
    'dessert topping': 'كريمة تزيين', 'snacks': 'سناكس', 'snack': 'سناك',
    'popcorn': 'فشار', 'chips': 'شيبسى',
    'sausage': 'سجق', 'frankfurter': 'فرانكفورتر', 'bologna': 'بولونى',
    'luncheon meat': 'لانشون', 'salami': 'سلامى', 'pate': 'باتيه',
    'burrito': 'بوريتو', 'pizza': 'بيتزا', 'egg rolls': 'سبرينج رول',
    'fast foods': 'وجبات سريعة', 'fast food': 'وجبات سريعة',
    'restaurant': 'مطاعم', 'school lunch': 'وجبة مدرسية',
    'babyfood': 'أكل أطفال', 'infant formula': 'لبن أطفال',
    'formulated bar': 'لوح بروتين/طاقة', 'leavening agents': 'خمائر',
    'rennin': 'منفحة', 'cheese food': 'جبنة مصنعة', 'cheese spread': 'جبنة قابلة للدهن',
    'cream substitute': 'بديل كريمة', 'chicken breast': 'صدور فراخ',
    'turkey from whole': 'ديك رومى', 'mcdonald\'s': 'ماكدونالدز', 'kfc': 'كنتاكى',
    'burger king': 'برجر كنج', 'subway': 'صب واى', 'pizza hut 14" cheese pizza': 'بيتزا هت',
    'taco bell': 'تاكو بيل', 'wendy\'s': 'ويندى', 'popeyes': 'بوباى',
    'pasta mix': 'مكرونة سريعة', 'rice and vermicelli mix': 'رز بالشعرية',
}

# أجزاء/أوصاف بتتضاف بعد الاسم
PART = {
    'breast': 'صدور', 'thigh': 'ورك', 'drumstick': 'دبوس', 'wing': 'جناح',
    'leg': 'فخدة', 'liver': 'كبدة', 'heart': 'قلب', 'kidney': 'كلاوى',
    'gizzard': 'قوانص', 'neck': 'رقبة', 'back': 'ظهر', 'giblets': 'أحشاء',
    'ground': 'مفروم', 'minced': 'مفروم', 'whole': 'كامل',
    'skinless': 'من غير جلد', 'meat only': 'لحم بس',
    'meat and skin': 'لحم وجلد', 'with skin': 'بالجلد',
    'boneless': 'من غير عضم', 'bone-in': 'بالعضم',
    'separable lean only': 'هبرة', 'separable lean and fat': 'هبرة ودهن',
    'skim': 'خالى الدسم', 'nonfat': 'خالى الدسم', 'fat free': 'خالى الدسم',
    'low fat': 'قليل الدسم', 'reduced fat': 'قليل الدسم',
    'whole milk': 'كامل الدسم', 'unsweetened': 'من غير سكر',
    'sweetened': 'محلّى', 'unsalted': 'من غير ملح', 'salted': 'بملح',
    'juice': 'عصير', 'peeled': 'مقشّر', 'unpeeled': 'بالقشرة',
    'with skin': 'بالقشرة', 'without skin': 'من غير قشرة',
    'enriched': 'مدعّم', 'whole grain': 'حبة كاملة', 'white': 'أبيض',
    'brown': 'أسمر', 'long-grain': 'حبة طويلة', 'french fried': 'محمّرة',
    'mashed': 'بورية', 'hash brown': 'هاش براون', 'flakes': 'رقائق',
    'powder': 'بودرة', 'concentrate': 'مركّز', 'smoked': 'مدخّن',
    'roll': 'رول', 'sliced': 'شرائح', 'chopped': 'مقطّع',
}

PREP_AR = {
    'fried': 'مقلى', 'roasted': 'مشوى فى الفرن', 'grilled': 'مشوى',
    'boiled': 'مسلوق', 'steamed': 'على البخار', 'baked': 'فى الفرن',
    'stewed': 'مسبّك', 'microwaved': 'ميكروويف', 'cooked': 'مطبوخ',
    'canned': 'معلّب', 'dried': 'مجفف', 'frozen': 'مجمّد', 'raw': 'نيّئ',
}

CAT_AR = {
    'Dairy and Egg Products': 'ألبان وبيض', 'Spices and Herbs': 'بهارات وأعشاب',
    'Baby Foods': 'أكل أطفال', 'Fats and Oils': 'دهون وزيوت',
    'Poultry Products': 'دواجن', 'Soups, Sauces, and Gravies': 'شوربة وصوصات',
    'Sausages and Luncheon Meats': 'سجق ولانشون', 'Breakfast Cereals': 'حبوب إفطار',
    'Fruits and Fruit Juices': 'فواكه وعصائر',
    'Vegetables and Vegetable Products': 'خضار',
    'Nut and Seed Products': 'مكسرات وبذور', 'Beef Products': 'لحوم بقرى',
    'Beverages': 'مشروبات', 'Finfish and Shellfish Products': 'أسماك ومأكولات بحرية',
    'Legumes and Legume Products': 'بقوليات',
    'Lamb, Veal, and Game Products': 'ضانى وبتلو',
    'Baked Products': 'مخبوزات', 'Sweets': 'حلويات',
    'Cereal Grains and Pasta': 'حبوب ومكرونة', 'Fast Foods': 'وجبات سريعة',
    'Meals, Entrees, and Side Dishes': 'وجبات وأطباق', 'Snacks': 'سناكس',
    'Restaurant Foods': 'مطاعم',
}


def prep_of(d):
    dl = d.lower()
    for pat, tag in PREP:
        if re.search(pat, dl):
            return tag
    return ''


def base_of(desc):
    b = STRIP.sub('', desc)
    b = re.sub(r',\s*,+', ',', b)
    return re.sub(r'\s{2,}', ' ', b).strip(' ,').lower()


def arabic_name(desc, prep):
    """اسم عربى مركّب: الكلمة الرئيسية + الأجزاء المعروفة + طريقة الطهى.
    بيرجّع '' لو الكلمة الرئيسية مش فى القاموس (ساعتها بيفضل الاسم الإنجليزى)."""
    dl = desc.lower()
    head = dl.split(',')[0].strip()
    ar = HEAD.get(head)
    if not ar:
        return ''
    parts = []
    for en_part, ar_part in PART.items():
        if re.search(r'\b' + re.escape(en_part) + r'\b', dl) and ar_part not in parts:
            parts.append(ar_part)
    name = ar + (' ' + ' '.join(parts[:3]) if parts else '')
    if prep:
        name += ' — ' + PREP_AR[prep]
    # مميِّز إضافى: صنف مجمّد/معلّب اتطبخ برضه (عشان مايتلخبطش مع الطازة)
    for extra, lbl in (('frozen', 'مجمّد'), ('canned', 'معلّب')):
        if extra in dl and prep != extra:
            name += f' ({lbl})'
            break
    return name.strip()


print('nutrients...')
per_food = collections.defaultdict(dict)
for r in rows('food_nutrient.csv'):
    nid = int(float(r['nutrient_id']))
    if nid in WANT and r['amount']:
        per_food[r['fdc_id']][WANT[nid]] = round(float(r['amount']), 2)

print('portions...')
portions = {}
for r in rows('food_portion.csv'):
    fid = r['fdc_id']
    if fid in portions:
        continue
    gw, mod, amt = r['gram_weight'], (r['modifier'] or '').strip(), r['amount'] or ''
    if gw and mod and mod.lower() != 'quantity not specified':
        try:
            g = float(gw)
        except ValueError:
            continue
        if 5 <= g <= 1000:
            portions[fid] = (f'{amt} {mod}'.strip(), round(g))

cats = {r['id']: r['description'] for r in rows('food_category.csv')}

print('build...')
items, dropped, dropped2, dropped_raw = [], 0, 0, 0
for r in rows('food.csv'):
    fid = r['fdc_id']
    n = per_food.get(fid)
    if not n or 'kcal' not in n:
        continue
    desc = r['description']
    cat = cats.get(r['food_category_id'], '')
    if cat in DROP_CATS or DROP_RE.search(desc):
        dropped += 1
        continue
    if drop2_hit(desc):
        dropped2 += 1
        continue
    pr = prep_of(desc)
    # لحمة/فراخ/سمك نيّئة -> مالهاش لزمة (محدش بياكلها كده)
    if pr == 'raw' and cat in RAW_MEAT_CATS:
        dropped_raw += 1
        continue
    it = {
        'id': int(fid), 'en': desc, 'cat': CAT_AR.get(cat, cat),
        'kcal': n.get('kcal', 0), 'p': n.get('protein', 0),
        'c': n.get('carbs', 0), 'f': n.get('fat', 0),
    }
    ar = arabic_name(desc, pr)
    if ar:
        it['ar'] = ar
    for k in ('fiber', 'sugar', 'sodium', 'chol', 'sat', 'calcium', 'iron', 'potassium'):
        if k in n:
            it[k] = n[k]
    if pr:
        it['prep'] = pr
    if fid in portions:
        it['pl'], it['pg'] = portions[fid]
    it['_base'] = base_of(desc)
    items.append(it)

# مجموعات طرق الطهى + إزالة التكرار (نفس الطريقة ونفس السعرات)
by_base = collections.defaultdict(list)
for it in items:
    by_base[it['_base']].append(it)

final, gid, multi = [], 0, 0
for base, lst in by_base.items():
    seen, uniq = set(), []
    for i in lst:
        key = (i.get('prep', ''), i['kcal'], i['p'], i['c'])
        if key in seen:
            continue
        seen.add(key)
        uniq.append(i)
    preps = {i.get('prep', '') for i in uniq}
    if len(uniq) > 1 and len(preps) > 1:
        gid += 1
        multi += 1
        for i in uniq:
            i['g'] = gid
    final.extend(uniq)

for it in final:
    del it['_base']

final.sort(key=lambda x: (x.get('ar') or x['en']))
json.dump(final, open('usda_foods.json', 'w', encoding='utf-8'),
          ensure_ascii=False, separators=(',', ':'))

size = os.path.getsize('usda_foods.json')
with_ar = sum(1 for i in final if 'ar' in i)
lines = [
    f'أصناف نهائية: {len(final)}',
    f'  اتشال (خنزير/خمور/قطبى): {dropped}',
    f'  اتشال (دم/جيلاتين/منفحة/كحول/خيل/ضفادع/شحم): {dropped2}',
    f'  اتشال (لحوم نيّئة): {dropped_raw}',
    f'  تكرار: {len(items)-len(final)}',
    f'حجم JSON: {size/1e6:.2f} MB',
    f'ليها اسم عربى: {with_ar} ({with_ar*100//len(final)}%)',
    f'مجموعات طرق طهى: {multi}   أصناف جواها: {sum(1 for i in final if "g" in i)}',
    f'ليها وزن حصة: {sum(1 for i in final if "pg" in i)}',
    '',
    '=== عينة أسماء عربية ===',
]
shown = 0
for i in final:
    if 'ar' in i and 'g' in i and shown < 25:
        lines.append(f'  {i["ar"]:42s} | {i["kcal"]:5.0f} kcal | {i["en"][:52]}')
        shown += 1
open('build3_out.txt', 'w', encoding='utf-8').write('\n'.join(lines))
