import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:provider/provider.dart';

import 'package:chinese_food_app/domain/entities/store.dart';
import 'package:chinese_food_app/domain/entities/visit_record.dart';
import 'package:chinese_food_app/domain/usecases/add_visit_record_usecase.dart';
import 'package:chinese_food_app/presentation/pages/visit_record/visit_record_form_page.dart';

import '../../helpers/mocks.mocks.dart';
