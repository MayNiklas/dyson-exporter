from setuptools import setup

setup(
    name='dyson_exporter',
    version='0.1',
    url='',
    license='',
    author='MayNiklas',
    author_email='info@niklas-steffen.de',
    description='',
    packages=['dyson_exporter'],
    entry_points={
        'console_scripts': [
            'dyson_exporter=dyson_exporter:main',
        ],
    },
)
