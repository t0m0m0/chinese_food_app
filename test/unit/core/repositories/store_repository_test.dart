import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:chinese_food_app/domain/entities/store.dart';
import 'package:chinese_food_app/domain/repositories/store_repository.dart';
import 'package:chinese_food_app/data/repositories/store_repository_impl.dart';
import 'package:chinese_food_app/data/datasources/store_local_datasource.dart';
import 'package:chinese_food_app/data/datasources/hotpepper_api_datasource.dart'
    show HotpepperApiDatasource;
import 'package:chinese_food_app/data/models/store_model.dart';
import 'package:chinese_food_app/data/models/hotpepper_store_model.dart';

// Mockクラスを生成するためのアノテーション
